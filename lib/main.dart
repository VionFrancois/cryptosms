import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptosms/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'back/db.dart';
import 'package:webcrypto/webcrypto.dart';

import 'back/messages_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO : Demander un code au démarrage de l'app
  await DatabaseHelper().initDatabase("1234");
  verifyContactsKeys();
  // SMSMonitor().checkForNewSMS();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final SMSMonitor _smsMonitor = SMSMonitor();

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
    // _smsMonitor.startMonitoring();
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