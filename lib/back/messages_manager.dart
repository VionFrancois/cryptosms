import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'db.dart';
import 'package:webcrypto/webcrypto.dart';



// List<String> recipients = ["+32..."];
// TODO : N'est plus utile mais sert d'exemple pour implémenter au bon endroit
// class Home extends StatelessWidget {
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Send sms to multiple"),),
//       body: Container(
//
//         child: Center(
//           child: Column(
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color                padding: EdgeInsets.symmetric(vertical: 16.0),
//                     textStyle: Theme.of(context).textTheme.button, // Use textTheme.button
//                   ),
//                   onPressed: () {
//                     _sendSMS("Coucou, je t'envoie ce message via mon projet d'application", recipients as String);
//                   },
//                   child: Text("Send Sms to "),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color                padding: EdgeInsets.symmetric(vertical: 16.0),
//                     textStyle: Theme.of(context).textTheme.button, // Use textTheme.button
//                   ),
//                   onPressed: () {
//                     // _getIncomingSMS();
//                   },
//                   child: Text("Send Sms to "),
//                 ),
//
//               ]),
//         ),
//       ),
//     );
//   }
// }

Future<List<SmsMessage>?> _getIncomingSMS(String address) async {
  try {
    // Start et count possible
    List<SmsMessage> messages = await SmsQuery().querySms(kinds:[SmsQueryKind.inbox] , address: address);
    return messages;
  } catch (e) {
    print('Erreur lors de la récupération des SMS: $e');
  }
  return null;
}

void _sendSMS(String message, String phoneNumber) async {
  final recipents = ["+${phoneNumber}"];
  String _result = await sendSMS(message: message, recipients: recipents, sendDirect: true)
      .catchError((onError) {
    print(onError);
  });
  print(_result);
}

Future<void> newContact(String phoneNumber, String name) async{
  final newContact = await createContact(phoneNumber, name);
  initHandshake(newContact!);
}

Future<Contact?> createContact(String phoneNumber, String name) async {
  // Verify that the contact does not exist
  if(await DatabaseHelper().getContact(phoneNumber) == null){
    // Generate new keys
    final keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    final publicKey = await keyPair.publicKey.exportJsonWebKey();
    final privateKey = await keyPair.privateKey.exportJsonWebKey();

    // Create contact
    Contact newContact = Contact(phoneNumber: phoneNumber, name: name, privateKey: json.encode(privateKey), publicKey: json.encode(publicKey), symmetricKey: "", lastReceivedMessageDate: DateTime(2000, 1, 1).toIso8601String(), lastReceivedMessage: "", seen : true);
    await DatabaseHelper().insertContact(newContact);
    return newContact;
  }
  return null;
  // TODO : Raise an error or something, we're trying to overwrite a contact (could be usefull)
}


void initHandshake(Contact contact){
  var message = "Hey ! J'utilise cryptoSMS pour chiffrer mes SMS, rentrons en contact et récupère le contrôle sur tes données. Télécharge l'application via F-Droid. (maybe one day)";
  var keyMessage = "cSMS key : ${contact.publicKey}";
  // final Uint8List header = Uint8List.fromList([0x12, 0x34, 0x56, 0x00]);
  _sendSMS(message, contact.phoneNumber);
  // Attends une seconde avant d'envoyer le 2eme message
  // Future.delayed(Duration(seconds: 2), () {_sendSMS(keyMessage, contact.phoneNumber);});
  _sendSMS(keyMessage, contact.phoneNumber);
}

void verifyContactsKeys() async{
  // TODO : Commenter
  final contacts = await DatabaseHelper().getAllContacts();
  for(Contact contact in contacts){
    if(contact.symmetricKey == ""){
      final key = await fetchKey(contact.phoneNumber);
      if(key != null){
        completeHandshake(contact, key);
      }
    }
  }
}


Future<String?> fetchKey(String phoneNumber) async{
  final messages = await _getIncomingSMS(phoneNumber);
  for (SmsMessage message in messages!) {
    var content = message.body!;
    if(content.startsWith("cSMS key : ")){
      final key = content.substring(11, content.length);
      return key;
    }
  }
  return null;
}

void completeHandshake(Contact contact, String otherKey) async{
  // Clé publique du contact
  final publicKeyJson = json.decode(otherKey);
  final publicKey = await EcdhPublicKey.importJsonWebKey(publicKeyJson, EllipticCurve.p256);
  // Clé privée de l'utilisateur pour ce contact
  final privateKeyJson = json.decode(contact.privateKey);
  final privateKey = await EcdhPrivateKey.importJsonWebKey(privateKeyJson, EllipticCurve.p256);

  final derivedKey = await privateKey.deriveBits(256, publicKey);
  final derivedKeyStr = derivedKey.toString();
  // Sauvegarde le message envoyé dans la base de données
  DatabaseHelper().updateSymmetricKey(contact.phoneNumber, derivedKeyStr);
}


List<bool> checkHeader(String encodedMessage){
  if(encodedMessage.length > 5){
    if(encodedMessage.substring(0,5) == "cSMS "){

      if(encodedMessage.length > 9){
        if(encodedMessage.substring(5,8) == "key"){
          return [true,true];
        }
      }
      return [true,false];
    }
  }
  return [false,false];
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
  Uint8List iv = generateRandomIV();
  // Convertis la clé de String à List<int>
  final List<String> numbers = contact.symmetricKey.substring(1, contact.symmetricKey.length - 1).split(', ');
  final List<int> key = numbers.map((string) => int.parse(string)).toList();

  // Clé pour AES CGM
  final aesGcmKey = await AesGcmSecretKey.importRawKey(key);

  // Message sous forme de bytes
  final Uint8List messageBytes = Uint8List.fromList(message.codeUnits);

  final encryptedMessageBytes = await aesGcmKey.encryptBytes(messageBytes, iv);

  final Uint8List full_message = Uint8List.fromList([...iv, ...encryptedMessageBytes]);

  final content = "cSMS " + base64.encode(full_message);

  _sendSMS(content, contact.phoneNumber);

  DatabaseHelper().newMessage(contact.phoneNumber, content, DateTime.now(), true);
}

Future<String> readEncryptedMessage(Contact contact, String encryptedMessage) async{
  // Structure of a message

  // |   header   |    IV    | cyphertext |
  // | cSMS (key) | 16 bytes |    ...     |

  final List<String> numbers = contact.symmetricKey.substring(1, contact.symmetricKey.length - 1).split(', ');
  final List<int> key = numbers.map((string) => int.parse(string)).toList();

  final aesGcmKey = await AesGcmSecretKey.importRawKey(key);

  final payloadBytes = base64.decode(encryptedMessage.substring(5)); // Remove the header

  final Uint8List iv = payloadBytes.sublist(0, 16); // Extract the first 16 bytes

  final cyphertextBytes = payloadBytes.sublist(16); // Remove the first 16 bytes

  final decryptedMessageBytes =  await aesGcmKey.decryptBytes(cyphertextBytes, iv);

  final decryptedMessage = String.fromCharCodes(decryptedMessageBytes);

  return decryptedMessage;
}


Future<List<List<dynamic>>> fetchConversation(Contact contact) async {
  List<List<dynamic>> conversation = [];

  try {
    List<SmsMessage> messages = await SmsQuery().querySms(
      kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
      address: contact.phoneNumber,
    );

    for (var message in messages) {
      var content = message.body!;
      List<bool> header = checkHeader(content);
      if (header[0] && !header[1]) {
        String? decryptedMessage;

        try{
          decryptedMessage = await readEncryptedMessage(contact, content);
          bool isReceived = message.kind == SmsMessageKind.received;

          conversation.add([decryptedMessage, isReceived, message.date]);
        }
        catch(e){
          print("Erreur lors du déchiffrement d'un message comprenant un header correct");
        }
      }
    }
  } catch (e) {
    print('Erreur lors de la récupération des messages chiffrés: $e');
  }

  // conversation.sort([a, b => a.date!.compareTo(b.date!));
  conversation.sort((a, b) => a[2].compareTo(b[2])); // a[2] et b[2] sont les dates

  return conversation;
}







class SMSMonitor {
  Timer? _timer;

  void startMonitoring() {
    const period = Duration(seconds: 10); // Définit la période de vérification
    _timer = Timer.periodic(period, (Timer t) {checkForNewSMS(); verifyContactsKeys();});
  }

  void stopMonitoring() {
    _timer?.cancel();
  }



  Future<List<Contact>?> checkForNewSMS() async {
    List<String> recentAddresses = [];
    List<Contact> recentContacts = [];
    try {
      int start = 0;
      int count = 50;
      List<SmsMessage> messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox], start: start, count: count);

      String? lastMessageDateString = await DatabaseHelper().getLastReceivedMessageDate();
      DateTime? lastMessageDate = DateTime.tryParse(lastMessageDateString ?? '');

      if (lastMessageDate != null) {
        int i = 0;
        while (i < messages.length && messages[i].date != null && lastMessageDate.isBefore(messages[i].date!)) {
          print(lastMessageDate.isBefore(messages[i].date!));
          // Si c'est un message chiffré
          if (messages[i].body != null && checkHeader(messages[i].body!)[0]) {
            String? address = messages[i].address;
            if (address != null) {
              // Si on n'a pas encore relevé ce contact
              if (!recentAddresses.contains(address)) {
                print("NOUVEAU MESSAGE");
                recentAddresses.add(address);
                await DatabaseHelper().newMessage(address, messages[i].body!, messages[i].date!, false);
              }
            }
          }
          i++;
          if (i == count) {
            start += count;
            count += count;
            messages = await SmsQuery().querySms(start: start, count: count);
            i = 0;
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des SMS: $e');
    }

    if (recentAddresses.isNotEmpty) {
      for (String address in recentAddresses) {
        try {
          Contact? contact = await DatabaseHelper().getContact(address);
          if (contact != null) {
            recentContacts.add(contact);
          }
        } catch (e) {
          print('Erreur lors de la récupération du contact: $e');
        }
      }
      return recentContacts;
    } else {
      return null;
    }
  }



}