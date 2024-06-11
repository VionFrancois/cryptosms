import 'package:sqflite_sqlcipher/sqflite.dart';

// Define a Contact with all the data in a row of the database
// It will be used in the different pages to interact with contact data
class Contact {
  String phoneNumber;
  String name;
  String privateKey;
  String publicKey;
  String symmetricKey;
  String lastReceivedMessageDate;
  String lastReceivedMessage;
  bool seen;

  Contact(
      {required this.phoneNumber,
        required this.name,
        required this.privateKey,
        required this.publicKey,
        required this.symmetricKey,
        required this.lastReceivedMessageDate,
        required this.lastReceivedMessage,
        required this.seen});

  // Creates a Map from the Contact object (to insert in database)
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'symmetricKey': symmetricKey,
      'lastReceivedMessageDate': lastReceivedMessageDate,
      'lastReceivedMessage': lastReceivedMessage,
      'seen': seen ? 1 : 0,
    };
  }
}

// Class for the database management and queries
class DatabaseHelper {
  // ===== Database management =====

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? db;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> initDatabase(String password) async {
    String databasesPath = await getDatabasesPath();
    String path = '${databasesPath}cryptosms.db';

    db = await openDatabase(path, password: password, version: 1, onCreate: _onCreate);
  }

  // Creates the table at first initialisation
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE contacts (
      phoneNumber TEXT PRIMARY KEY,
      name TEXT,
      privateKey TEXT,
      publicKey TEXT,
      symmetricKey TEXT,
      lastReceivedMessageDate DATETIME,
      lastReceivedMessage TEXT,
      seen INTEGER
    );
  ''');
  }

  // ===== Database queries =====

  Future<int> insertContact(Contact contact) async {
    // Uses the toMap method to convert a Contact object to a valid row of the database
    final result = await db!.insert('contacts', contact.toMap());
    return result;
  }

  Future<List<Contact>> getAllContacts() async {
    // Retrieves all contacts SORTED by recent activity
    final List<Map<String, dynamic>> maps = await db!.query(
      'contacts',
      orderBy: 'lastReceivedMessageDate DESC',
    );

    // Converts the List of Map (database row) to a List of Contact objects
    return List.generate(maps.length, (i) {
      return Contact(
          phoneNumber: maps[i]['phoneNumber'],
          name: maps[i]['name'],
          privateKey: maps[i]['privateKey'],
          publicKey: maps[i]['publicKey'],
          symmetricKey: maps[i]['symmetricKey'],
          lastReceivedMessageDate: maps[i]['lastReceivedMessageDate'],
          lastReceivedMessage: maps[i]['lastReceivedMessage'],
          seen: maps[i]['seen'] == 1);
    });
  }

  Future<Contact?> getContact(String phoneNumber) async {
    List<Map<String, dynamic>> maps = await db!.query(
      'contacts',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );

    // Returns null if the contact doesn't exists
    if (maps.isEmpty) {
      return null;
    }

    // Otherwise, converts the Map (database row) to a Contact object
    return Contact(
        phoneNumber: maps[0]['phoneNumber'],
        name: maps[0]['name'],
        privateKey: maps[0]['privateKey'],
        publicKey: maps[0]['publicKey'],
        symmetricKey: maps[0]['symmetricKey'],
        lastReceivedMessageDate: maps[0]['lastReceivedMessageDate'],
        lastReceivedMessage: maps[0]['lastReceivedMessage'],
        seen: maps[0]['seen'] == 1);
  }

  Future<int> updateSymmetricKey(String phoneNumber, String newSymmetricKey) async {
    return await db!.update(
      'contacts',
      {'symmetricKey': newSymmetricKey},
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
  }

  Future<String?> getLastReceivedMessageDate() async {
    List<Map<String, dynamic>> messages = await db!.query(
      'contacts',
      columns: ['lastReceivedMessageDate'],
      orderBy: 'lastReceivedMessageDate DESC',
      limit: 1,
    );

    if (messages.isNotEmpty) {
      return messages[0]['lastReceivedMessageDate'] as String?;
    }

    return null;
  }

  // Stores the last message sent/received from a contact
  Future<int> newMessage(String phoneNumber, String newMessage, DateTime time, bool seen) async {
    return await db!.update(
      'contacts',
      {
        'lastReceivedMessage': newMessage,
        'lastReceivedMessageDate': time.toIso8601String(),
        'seen': seen ? 1 : 0,
      },
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
  }

  // Marks the contact's messages as seen
  Future<void> messageSeen(String phoneNumber) async {
    await db!.update(
      'contacts',
      {'seen': 1},
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
  }
}
