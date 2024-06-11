import 'dart:async';
import 'package:cryptosms/back/sms_manager.dart';
import 'package:cryptosms/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'back/db.dart';
import 'back/crypto.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO : Demander un code au démarrage de l'app
  await DatabaseHelper().initDatabase("1234");

  // TODO : Fetch d'autres truc ici ?
  CryptoManager().verifyContactsKeys();
  SMSManager smsMonitor = SMSManager();
  // SMSMonitor smsMonitor = SMSMonitor();
  // smsMonitor.checkForNewSMS();
  smsMonitor.startMonitoring();

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
  void dispose() {
    // _smsMonitor.stopMonitoring();
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