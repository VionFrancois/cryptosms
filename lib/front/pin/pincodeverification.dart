import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cryptosms/front/pin/createpinscreen.dart';
import 'package:cryptosms/front/pin/pincodewidget.dart';

import '../../back/db.dart';



class PinCodeVerification extends StatefulWidget {
  @override
  _PinCodeVerificationState createState() => _PinCodeVerificationState();
}

class _PinCodeVerificationState extends State<PinCodeVerification> {
  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  void _checkPin() async {
    if (await DatabaseHelper().databaseExists()) {
      // if PIN exists, direct the user to the login screen.
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => PinCodeWidget()));
    } else {
      // If no PIN exists, direct the user to the PIN creation screen.
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => CreatePinScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
