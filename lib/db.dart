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
  String getPhoneNumber(){
    return phoneNumber;
  }

  String getName(){
    return name;
  }

  // On peut éviter d'y accéder en instanciant le contact et en intéragissant avec via des fonctions
  // Genre create symmetricKey() où on donnera la clé de l'autre reçu et encrypt() qui utilisera la clé mais sans
  // la sortir de l'objet contact
  // String getPrivateKey(){
  //   return privateKey;
  // }
  //
  // String getPublicKey(){
  //   return publicKey;
  // }

  // String getSymmetricKey(){
  //
  // }

  String encrypt(String message){
    // TODO : Implement encryption with symmetricKey
    return message;
  }

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
    final result = await db!.insert('contacts', contact.toMap());
    return result;
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

  Future<Contact?> getContact(String phoneNumber) async {
    List<Map<String, dynamic>> maps = await db!.query(
      'contacts',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );

    // Si aucun contact n'est trouvé, retourne null
    if (maps.isEmpty) {
      return null;
    }

    // Sinon, crée et retourne le contact à partir des données de la base de données
    return Contact(
      phoneNumber: maps[0]['phoneNumber'],
      name: maps[0]['name'],
      privateKey: maps[0]['privateKey'],
      publicKey: maps[0]['publicKey'],
      symmetricKey: maps[0]['symmetricKey'],
    );
  }

  Future<int> updateSymmetricKey(String phoneNumber, String newSymmetricKey) async {
    return await db!.update(
      'contacts', // Nom de la table
      {'symmetricKey': newSymmetricKey},
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
  }

}
