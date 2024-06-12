import 'package:cryptosms/back/db.dart';
import 'package:cryptosms/front/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../back/crypto.dart';
import '../../back/sms_manager.dart';
import '../start_page.dart';

//CreatePinScreen widget use to create a new PIN.
class CreatePinScreen extends StatefulWidget {
  @override
  _CreatePinScreenState createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String pin = '';
  String newPin = '';
  String confirmNewPin = '';

  void _setPin() async {
    await DatabaseHelper().initDatabase(newPin);

    CryptoManager().verifyContactsKeys();
    SMSManager smsMonitor = SMSManager();
    smsMonitor.startMonitoring();

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => StartPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Image.asset('assets/icon.png'),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'CryptoSMS',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 80),
                    const Text(
                      'Create a PIN code',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    buildPinField('New PIN code', (value) {
                      newPin = value;
                    }),
                    SizedBox(height: 5),
                    buildPinField('Confirm your new PIN code', (value) {
                      confirmNewPin = value;
                    }),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _setPin,
                      child: Text('Save PIN code'),
                    ),
                  ],
                ),
              ]),
        ));
  }

  Widget buildPinField(String label, Function(String) onChanged) {
    return TextField(
      obscureText: true,
      maxLength: 4,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
        hintText: 'Enter a 4 numbers PIN code',
      ),
    );
  }
}
