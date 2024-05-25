import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptosms/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'db.dart';
import 'package:webcrypto/webcrypto.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDatabase("1234");
  verifyContactsKeys();
  SMSMonitor().checkForNewSMS();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SMSMonitor _smsMonitor = SMSMonitor();

  void requestSmsPermission() async {
    if (await Permission.sms.status.isDenied) {
      if (await Permission.sms.request().isGranted) {
        print('SMS permission granted');
      } else {
        print('SMS permission denied');
      }
    } else {
      print('SMS permission already granted');
    }
  }

  @override
  void initState(){
    super.initState();
    requestSmsPermission(); // Request permission on app initialization
    _smsMonitor.startMonitoring();
  }

  @override
  void dispose() {
    _smsMonitor.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      debugShowCheckedModeBanner: false,

      home: MyHomePage(),
    );
  }
}

List<String> recipients = ["+32..."];

class Home extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send sms to multiple"),),
      body: Container(

        child: Center(
          child: Column(
            children: [
              ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color                padding: EdgeInsets.symmetric(vertical: 16.0),
                textStyle: Theme.of(context).textTheme.button, // Use textTheme.button
              ),
              onPressed: () {
                _sendSMS("Coucou, je t'envoie ce message via mon projet d'application", recipients as String);
              },
              child: Text("Send Sms to "),
            ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color                padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: Theme.of(context).textTheme.button, // Use textTheme.button
                ),
                onPressed: () {
                  // _getIncomingSMS();
                },
                child: Text("Send Sms to "),
              ),

        ]),
          ),
        ),
    );
  }
}

Future<List<SmsMessage>?> _getIncomingSMS(String address) async {
  try {
    // Start et count possible
    List<SmsMessage> messages = await SmsQuery().querySms(kinds:[SmsQueryKind.inbox] , address: "+${address}");
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
    // TODO : Generate IV
    final keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    final publicKey = await keyPair.publicKey.exportJsonWebKey();
    final privateKey = await keyPair.privateKey.exportJsonWebKey();

    // Create contact
    Contact newContact = Contact(phoneNumber: phoneNumber, name: name, privateKey: json.encode(privateKey), publicKey: json.encode(publicKey), symmetricKey: "", lastReceivedMessageDate: DateTime(1970), IV: "TODO : Change here", counter: 0);
    await DatabaseHelper().insertContact(newContact);
    return newContact;
  }
  return null;
  // TODO : Raise an error or something, we're trying to overwrite a contact (could be usefull)
}


void initHandshake(Contact contact){
  var message = "Hey ! J'utilise cryptoSMS pour chiffrer mes SMS, rentrons en contact et récupère le contrôle sur tes données. Télécharge l'application via F-Droid. (maybe one day)";
  var keyMessage = "cryptoSMS key : ${contact.publicKey}";
  // TODO : Chiffrement du message avec une clé connue ?
  _sendSMS(message, contact.phoneNumber);
  // Attends une seconde avant d'envoyer le 2eme message
  Future.delayed(Duration(seconds: 1), () {_sendSMS(keyMessage, contact.phoneNumber);});
}

void verifyContactsKeys() async{
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
    if(content.startsWith("cryptoSMS key : ")){
        final key = content.substring(16, content.length);
        return key;
    }
  }
  return null;
}

void completeHandshake(Contact contact, String otherKey) async{
  // TODO : Recevoir l'IV de l'autre et en prendre un totalement opposé ?
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


bool checkHeader(String encodedMessage){
  Uint8List messageBytes = base64.decode(encodedMessage);

  if (messageBytes.length >= 3) {
    if (messageBytes[0] == 0x12 && messageBytes[1] == 0x34 && messageBytes[2] == 0x56) {
      return true;
    }
  }
  return false;
}


void sendEncryptedMessage(Contact contact, String message) async {
  Uint8List iv = Uint8List.fromList(contact.IV.codeUnits);
  incrementUint8List(iv, contact.counter);

  // Convertis la clé de String à List<int>
  final List<String> numbers = contact.symmetricKey.substring(1, contact.symmetricKey.length - 1).split(', ');
  final List<int> key = numbers.map((string) => int.parse(string)).toList();

  // Clé pour AES CGM
  final aesGcmKey = await AesGcmSecretKey.importRawKey(key);

  // Message sous forme de bytes
  // TODO : Ajouter le header
  // TODO : Concaténer l'IV au message
  final messageBytes = Uint8List.fromList(message.codeUnits);

  final encryptedMessageBytes = await aesGcmKey.encryptBytes(messageBytes, iv);

  final encryptedMessage = base64.encode(encryptedMessageBytes);

  _sendSMS(encryptedMessage, contact.phoneNumber);
  int counter = contact.counter + 1;
  await DatabaseHelper().updateCounter(contact.phoneNumber, counter);
}

Future<String> readEncryptedMessage(Contact contact, String encryptedMessage) async{
  // TODO : Lire l'IV qui est concaténé au message

  final List<String> numbers = contact.symmetricKey.substring(1, contact.symmetricKey.length - 1).split(', ');
  final List<int> key = numbers.map((string) => int.parse(string)).toList();

  final aesGcmKey = await AesGcmSecretKey.importRawKey(key);
  // TODO : Retirer le header
  final messageBytes = base64.decode(encryptedMessage);

  final List<int> iv = [1,2,3]; // TODO : Lire l'IV du message

  final decryptedMessageBytes =  await aesGcmKey.decryptBytes(messageBytes, iv);

  final decryptedMessage = String.fromCharCodes(decryptedMessageBytes);

  return decryptedMessage;
}

void incrementUint8List(Uint8List iv, int counter) {
  for (int i = iv.length - 1; i >= 0; i--) {
    if (iv[i] < 255 - counter + 1) {
      iv[i] += counter;
      break;
    } else {
      iv[i] = 0;
    }
  }
}


class SMSMonitor {
  Timer? _timer;

  void startMonitoring() {
    const period = Duration(seconds: 5); // Définit la période de vérification
    _timer = Timer.periodic(period, (Timer t) => checkForNewSMS());
  }

  void stopMonitoring() {
    _timer?.cancel();
  }


  var lastMessage;

  Future<List<Contact>?> checkForNewSMS() async {
    var recentAddresses;
    try{
      int start = 0;
      int count = 5;
      List<SmsMessage> messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox], start: start, count: count);
      lastMessage ??= DatabaseHelper().getLastReceivedMessageDate(); // Si lastMessage == null, on va le fetch
      int i = 0;
      while(lastMessage.lastReceivedMessage != messages[i].dateSent){
        // Si c'est un message chiffré
        if(checkHeader(messages[i].body!)){
          String? address = messages[i].address;
          // Si on a pas encore relevé ce contact
          if (!(recentAddresses.contains(address))){
            recentAddresses.add(address);
          }
        }
        i += 1;
        if (i == count){
          start = start + count;
          count = count + count;
          messages = await SmsQuery().querySms(start: start, count: count);
          i = 0;
        }
      }

    } catch (e) {
      print('Erreur lors de la récupération des SMS: $e');
    }

    // TODO : Génère des erreurs quand c'est null
    if (recentAddresses.isNotEmpty) {
      var recentContacts;
      for (String address in recentAddresses) {
        recentContacts.add(await DatabaseHelper().getContact(address));
      }
      return recentContacts;
    } else{
      return null;
    }
  }


}