import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class Contact {
  String phoneNumber;
  String name;
  String privateKey;
  String publicKey;
  String symmetricKey;
  String lastReceivedMessageDate;
  String lastReceivedMessage;
  bool seen;

  Contact({required this.phoneNumber, required this.name, required this.privateKey, required this.publicKey, required this.symmetricKey, required this.lastReceivedMessageDate, required this.lastReceivedMessage, required this.seen});

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'privateKey': privateKey,
      'publicKey' : publicKey,
      'symmetricKey' : symmetricKey,
      'lastReceivedMessageDate' : lastReceivedMessageDate,
      'lastReceivedMessage' : lastReceivedMessage,
      'seen': seen ? 1 : 0,
    };
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


  // ============ CONTACTS ============

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
        lastReceivedMessageDate: maps[i]['lastReceivedMessageDate'],
        lastReceivedMessage: maps[i]['lastReceivedMessage'],
        seen: maps[i]['seen'] == 1
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
      lastReceivedMessageDate: maps[0]['lastReceivedMessageDate'],
      lastReceivedMessage: maps[0]['lastReceivedMessage'],
      seen: maps[0]['seen'] == 1
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

  Future<String?> getLastReceivedMessageDate() async {
    try {
      List<Map<String, dynamic>> messages = await db!.rawQuery(
          'SELECT lastReceivedMessageDate FROM contacts ORDER BY lastReceivedMessageDate DESC LIMIT 1');

      if (messages.isNotEmpty) {
        return messages.first['lastReceivedMessageDate'] as String?;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la date du dernier message reçu: $e');
    }
    return null; // Si aucun résultat n'est trouvé ou en cas d'erreur
  }


  Future<int> updateCounter(String phoneNumber, int counter) async {
    return await db!.update(
      'contacts', // Nom de la table
      {'counter': counter},
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
  }

}
