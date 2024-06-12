import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'front/pin/pincodeverification.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  void requestSmsPermission() async {
    if (await Permission.sms.status.isDenied) {
      if (!await Permission.sms.request().isGranted) {
        throw Exeption("The application needs the permissions for SMS")
      }
    }
  }

  @override
  void initState() {
    super.initState();
    requestSmsPermission();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Launch Pin code at starting
      home: PinCodeVerification(),
    );
  }
}
