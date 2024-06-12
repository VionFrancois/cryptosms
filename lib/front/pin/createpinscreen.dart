import 'package:cryptosms/back/db.dart';
import 'package:cryptosms/front/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../back/crypto.dart';
import '../../back/sms_manager.dart';

class CreatePinScreen extends StatefulWidget {
  @override
  _CreatePinScreenState createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String pin = '';
  String newPin = '';
  String confirmNewPin = '';

  void _setPin() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('has_pin', true);
    // await prefs.setString('pin', newPin);
    await DatabaseHelper().initDatabase(newPin);

    CryptoManager().verifyContactsKeys();
    SMSManager smsMonitor = SMSManager();
    smsMonitor.startMonitoring();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => MyHomePage()));
  }

  @override
  Widget build(BuildContext context) {
    // Ajoutez ici l'interface utilisateur pour créer un nouveau PIN
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
                      width: 60, // Ajustez selon la taille de votre icône
                      height: 60, // Ajustez selon la taille de votre icône
                      decoration: BoxDecoration(
                        color: Colors.white, // Fond blanc de l'icône
                        shape: BoxShape.circle, // Forme circulaire
                        border: Border.all(
                          color: Colors.white, // Bordure noire de l'icône
                          width: 2, // Épaisseur de la bordure
                        ),
                      ),
                      child: Center(
                        child: Image.asset('assets/icon.png'),
                      ),
                    ),

                    const SizedBox(height: 5),
                    const Text(
                      'CryptoSMS', // Le texte en dessous de l'icône
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 80),
                    const Text(
                      'Créer un code PIN',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Champ pour entrer le nouveau code PIN
                    buildPinField('Nouveau code PIN', (value) {
                      newPin = value;
                    }),
                    SizedBox(height: 5),
                    // Champ pour confirmer le nouveau code PIN
                    buildPinField('Confirmer le nouveau code PIN', (value) {
                      confirmNewPin = value;
                    }),
                    //SizedBox(height: 20),
                    // Bouton pour enregistrer le code PIN

                    SizedBox(height: 20),
                    ElevatedButton(
                      //le code PIN crée va être enregistré dans SharedPreferences.
                      onPressed: _setPin,
                      child: Text('Enregistrer le PIN'),
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
        hintText: 'Entrez un code PIN à 4 chiffres',
      ),
    );
  }
}
