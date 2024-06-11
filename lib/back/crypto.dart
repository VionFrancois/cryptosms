import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:webcrypto/webcrypto.dart';
import 'db.dart';
import 'sms_manager.dart';

// This class manage the protocol and the cryptographic operations
class CryptoManager {
  // Initialise the DatabaseHelper to interact with the database
  final DatabaseHelper db = DatabaseHelper();

  Future<Contact?> createContact(String phoneNumber, String name) async {
    // Verify that the contact does not exists
    if (await db.getContact(phoneNumber) == null) {
      // Generate new keys
      final keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
      final publicKey = await keyPair.publicKey.exportJsonWebKey();
      final privateKey = await keyPair.privateKey.exportJsonWebKey();

      // Creates the Contact object and insert it in the database
      Contact newContact = Contact(
        phoneNumber: phoneNumber,
        name: name,
        privateKey: json.encode(privateKey),
        publicKey: json.encode(publicKey),
        symmetricKey: "",
        lastReceivedMessageDate: DateTime(2000, 1, 1).toIso8601String(),
        lastReceivedMessage: "",
        seen: true,
      );
      await db.insertContact(newContact);
      return newContact;
    }
    // The contact already exists, we return null
    return null;
  }

  void initHandshake(Contact contact) { // TODO : N'appeller que si l'autre personne n'a pas envoyé de clé (vérifier si une clé existe avant d'appeler)
    // Sends the invitation message and the public key for symmetric key computation
    String message =
        "Hello ! I use cryptoSMS to encrypt my SMS, let's get in touch and regain control over your data. Download the application via ...";
    var keyMessage = "cSMS key : ${contact.publicKey}";
    SMSManager().sendSMS(message, contact.phoneNumber);
    SMSManager().sendSMS(keyMessage, contact.phoneNumber);
  }

  void verifyContactsKeys() async {
    // Verifies if some contacts sent their key
    final contacts = await db.getAllContacts();
    for (Contact contact in contacts) {
      if (contact.symmetricKey.isEmpty) {
        final key = await fetchKey(contact.phoneNumber);
        if (key != null) {
          completeHandshake(contact, key);
        }
      }
    }
  }

  Future<String?> fetchKey(String phoneNumber) async {
    // For a specific number, we go through all the received message and look for a cryptoSMS key
    final messages = await SMSManager().getReceivedSMS(phoneNumber);
    if (messages != null) {
      for (SmsMessage message in messages) {
        var content = message.body!;
        if (content.startsWith("cSMS key : ")) {
          final key = content.substring(11);
          return key;
        }
      }
    }
    return null;
  }

  void completeHandshake(Contact contact, String otherKey) async {
    // Gather all the necessary keys
    final publicKeyJson = json.decode(otherKey);
    final publicKey =
        await EcdhPublicKey.importJsonWebKey(publicKeyJson, EllipticCurve.p256);
    final privateKeyJson = json.decode(contact.privateKey);
    final privateKey = await EcdhPrivateKey.importJsonWebKey(
        privateKeyJson, EllipticCurve.p256);

    // Creates the symmetric key from the previous keys and stores it in database
    final derivedKey = await privateKey.deriveBits(256, publicKey);
    final derivedKeyStr = derivedKey.toString();
    db.updateSymmetricKey(contact.phoneNumber, derivedKeyStr);
  }

  List<bool> checkHeader(String encodedMessage) {
    // Verifies what the type of message
    // No header -> Classic message
    // Starts with "cSMS" -> cSMS message
    // Starts with "cSMS key" -> cSMS key exchange
    if (encodedMessage.length > 5 && encodedMessage.startsWith("cSMS ")) {
      if (encodedMessage.length > 9 &&
          encodedMessage.substring(5, 8) == "key") {
        return [true, true]; // cSMS key exchange
      }
      return [true, false]; // cSMS message
    }
    return [false, false]; // Classic message
  }

  Uint8List generateRandomIV() {
    final random = Random.secure();
    final iv = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  void sendEncryptedMessage(Contact contact, String message) async {
    // Generate the IV
    Uint8List iv = generateRandomIV();

    // Retrieve the symmetric key
    final List<String> numbers = contact.symmetricKey
        .substring(1, contact.symmetricKey.length - 1)
        .split(', ');
    final List<int> key = numbers.map((string) => int.parse(string)).toList();
    final aesGcmKey = await AesGcmSecretKey.importRawKey(key);

    // Encrypt the message
    final Uint8List messageBytes = Uint8List.fromList(message.codeUnits);
    final encryptedMessageBytes =
        await aesGcmKey.encryptBytes(messageBytes, iv);
    final Uint8List fullMessage =
        Uint8List.fromList([...iv, ...encryptedMessageBytes]);
    // Adds the header
    final content = "cSMS " + base64.encode(fullMessage);

    // Sends the message via SMS and stores it as the last message to a contact
    SMSManager().sendSMS(content, contact.phoneNumber);
    db.newMessage(contact.phoneNumber, content, DateTime.now(), true);
  }

  Future<String> readEncryptedMessage(Contact contact, String encryptedMessage) async {
    // Retrieves the symmetric key
    final List<String> numbers = contact.symmetricKey
        .substring(1, contact.symmetricKey.length - 1)
        .split(', ');
    final List<int> key = numbers.map((string) => int.parse(string)).toList();
    final aesGcmKey = await AesGcmSecretKey.importRawKey(key);

    // Removes the message's header, divides the IV and the payload
    final payloadBytes = base64.decode(encryptedMessage.substring(5));
    final Uint8List iv = payloadBytes.sublist(0, 16);
    final Uint8List cyphertextBytes = payloadBytes.sublist(16);

    // Decrypts the message
    final decryptedMessageBytes = await aesGcmKey.decryptBytes(cyphertextBytes, iv);

    // Returns the String composed by the Bytes of the decrypted text
    return String.fromCharCodes(decryptedMessageBytes);
  }
}
