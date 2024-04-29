import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'db.dart';
import 'package:webcrypto/webcrypto.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDatabase("1234");
  final phoneNumber = "";
  final name = "";
  newContact(phoneNumber, name);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

List<String> recipients = ["+32"];

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
    // Récupérer les SMS entrants
    // int start = 1;
    // int count = 20;
    List<SmsMessage> messages = await SmsQuery().querySms(address: address);
    return messages;
    // Faire quelque chose avec les messages reçus, par exemple les afficher
    // for (SmsMessage message in messages) {
    //   print('SMS reçu de ${message.address}: ${message.body}');
    //   // Vous pouvez également traiter les messages reçus comme vous le souhaitez ici
    // }
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
    Contact newContact = Contact(phoneNumber: phoneNumber, name: name, privateKey: json.encode(privateKey), publicKey: json.encode(publicKey), symmetricKey: "");
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


Future<String?> fetchKey(String phoneNumber) async{
  // TODO : Tester sur un téléphone
  final messages = await _getIncomingSMS(phoneNumber);
  var key = "la clé quoi";
  for (SmsMessage message in messages!) {
    var content = message.body!;
    if(content.startsWith("cryptoSMS key : ")){
        final key = content.substring(15, content.length);
        return key;
    }
    print('SMS reçu de ${message.address}: ${message.body}');
  }
  return null;
}