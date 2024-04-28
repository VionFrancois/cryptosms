import 'package:sqflite_sqlcipher/sqflite.dart';

class Contact {
  String phoneNumber;
  String name;
  String privateKey;
  String publicKey;
  String symmetricKey;

  Contact({required this.phoneNumber, required this.name, required this.privateKey, required this.publicKey, required this.symmetricKey});

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'privateKey': privateKey,
      'publicKey' : publicKey,
      'symmetricKey' : symmetricKey,
    };
  }

  // TODO : Implémenter des getter
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? db;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> initDatabase(String password) async {
    String databasesPath = await getDatabasesPath();
    String path = '${databasesPath}your_database.db';

    db = await openDatabase(path, password: password, version: 1, onCreate: _onCreate);
  }

// Méthodes pour manipuler la base de données

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts (
        phoneNumber TEXT PRIMARY KEY,
        name TEXT,
        privateKey TEXT,
        publicKey TEXT,
        symmetricKey TEXT
      )
    ''');
  }

  // Méthode pour insérer un contact dans la table
  Future<int> insertContact(Contact contact) async {
    return await db!.insert('contacts', contact.toMap());
  }

  // Méthode pour récupérer tous les contacts de la table
  Future<List<Contact>> getAllContacts() async {
    final List<Map<String, dynamic>> maps = await db!.query('contacts');

    return List.generate(maps.length, (i) {
      return Contact(
        phoneNumber: maps[i]['phoneNumber'],
        name: maps[i]['name'],
        privateKey: maps[i]['privateKey'],
        publicKey: maps[i]['publicKey'],
        symmetricKey: maps[i]['symmetricKey'],
      );
    });
  }

}
