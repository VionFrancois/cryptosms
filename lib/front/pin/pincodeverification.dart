import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:cryptosms/front/pin/createpinscreen.dart';
import 'package:cryptosms/front/pin/pincodewidget.dart';

import '../../back/db.dart';


//Avant de se connecter, on va ajouter une étape de vérification
//pour déteminer si un code PIN a déjà été créé.
//Si ce n'est pas le cas, l'utlisateur sera invité à en créer un

class PinCodeVerification extends StatefulWidget {
  //la classe PinCodeVerification va vérifier si un code PIN existe déjà lors de démarrage de notre application.
  //Si ce n'est pas le cas, l'utlisateur est redirigé vers CreatePinScreen pour créer un nouveau code PIN.
  // Une fois le code PIN créé, il est enregistré à l’aide de SharedPreferences et l’utilisateur est redirigé
  // vers PinCodeWidget pour se connecter avec le nouveau code PIN.
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
    // final prefs = await SharedPreferences.getInstance();
    // final hasPin = prefs.getBool('has_pin') ?? false;
    if (await DatabaseHelper().databaseExists()) {
      // Si un PIN existe, dirigez l'utilisateur vers l'écran de connexion
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => PinCodeWidget()));
    } else {
      // Si aucun PIN n'existe, dirigez l'utilisateur vers l'écran de création de PIN
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => CreatePinScreen()));
    }
  }


  // void verifyPin() async {
  //   // Récupérez le code PIN correct enregistré dans SharedPreferences
  //   final String correctPin = prefs.getString('pin') ?? '';
  //   if (enteredPin == correctPin){
  //     // Si le PIN est correct, naviguez vers une nouvelle page
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => MyHomePage()),
  //     );
  //   } else {
  //     // Si le PIN est incorrect, affichez un message d'erreur
  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: const Text('Erreur'),
  //           content: const Text('Le code PIN est incorrect.'),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 //Navigator.of(context).pop(); // Fermez la boîte de dialogue
  //                 Navigator.push(context,
  //                   MaterialPageRoute(builder: (context) => CreatePinScreen()),);
  //
  //               },
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        //Le CircularProgressIndicator indique que l’application est occupée
        // et qu’une tâche est en cours d’exécution
        child: CircularProgressIndicator(),
      ),
    );
  }
}
