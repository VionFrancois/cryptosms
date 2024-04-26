import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:cryptography/cryptography.dart';

void main(){
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
  void initState() {
    super.initState();
    requestSmsPermission(); // Request permission on app initialization
    _privateKeyManager();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

List<String> recipents = ["+32..."];

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
                _sendSMS("Coucou, je t'envoie ce message via mon projet d'application", recipents);
              },
              child: Text("Send Sms to "),
            ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color                padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: Theme.of(context).textTheme.button, // Use textTheme.button
                ),
                onPressed: () {
                  _getIncomingSMS();
                },
                child: Text("Send Sms to "),
              ),

        ]),
          ),
        ),
    );
  }
}

Future<void> _getIncomingSMS() async {
  try {
    // Récupérer les SMS entrants
    int start = 1;
    int count = 20;
    String address = "+32...";
    List<SmsMessage> messages = await SmsQuery().querySms(address: address);
    print(messages);

    // Faire quelque chose avec les messages reçus, par exemple les afficher
    for (SmsMessage message in messages) {
      print('SMS reçu de ${message.address}: ${message.body}');
      // Vous pouvez également traiter les messages reçus comme vous le souhaitez ici
    }
  } catch (e) {
    print('Erreur lors de la récupération des SMS: $e');
  }
}

void _sendSMS(String message, List<String> recipents) async {
  String _result = await sendSMS(message: message, recipients: recipents,sendDirect: true)
      .catchError((onError) {
    print(onError);
  });
  print(_result);
}

Future<void> _privateKeyManager() async{
  final keyPair = await X25519().newKeyPair();
  final publicKey = keyPair.extractPublicKey();
  // TODO : Trouver un moyen d'envoyer la clé publique car ici elle est uniquement sous forme d'objet
  print('Clé publique: ${publicKey}');
}