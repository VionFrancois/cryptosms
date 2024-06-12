import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cryptosms/front/home_page.dart';
import '../../back/crypto.dart';
import '../../back/db.dart';
import '../../back/sms_manager.dart';



class PinCodeWidget extends StatefulWidget {
  const PinCodeWidget({super.key});

  @override
  State<PinCodeWidget> createState() => _PinCodeWidgetState();
}

class _PinCodeWidgetState extends State<PinCodeWidget> {
  String enteredPin = '';
  //String newPin = ''; // Variable pour stocker le nouveau code PIN
  bool isPinVisible = false;

  // bool isCreatingPin = true; // Indique si l'utilisateur est en train de créer un code PIN
  //final String correctPin = '1234'; // Le PIN correct
  // la méthode _checkPin ici va  vérifier si le code PIN entré correspond au code PIN enregistré dans SharedPreferences.
  // Si c’est le cas, l'utilisateur va se connecter directement à l'application.
  // Sinon, il affiche un message d’erreur
  // void _checkPin() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final correctPin = prefs.getString('pin') ?? '';
  //   if (enteredPin == correctPin) {
  //     // Le code PIN est correct, naviguez vers l'écran suivant ou montrez un message de succès
  //   } else {
  //     // Le code PIN est incorrect, montrez un message d'erreur
  //   }
  // }

  /// this widget will be use for each digit
  Widget numButton(int number) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton(
        onPressed: () {
          setState(() {
            if (enteredPin.length < 4) {
              enteredPin += number.toString();
            }
          });
        },
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  void verifyPin() async {

    try {
      await DatabaseHelper().initDatabase(enteredPin);

      CryptoManager().verifyContactsKeys();
      SMSManager smsMonitor = SMSManager();
      smsMonitor.startMonitoring();

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),);

    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('The PIN code is incorrect'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermez la boîte de dialogue
                },
                child: const Text('OK'),
              ),
            ],
          );
        }
      );
    }
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
                  'Enter your PIN code',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Votre code PIN doit contenir 4 chiffres au maximum',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    //fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            /// pin code area
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                    (index) {
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    width: isPinVisible ? 50 : 16,
                    height: isPinVisible ? 50 : 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      color: index < enteredPin.length
                          ? isPinVisible
                          ? Colors.green
                          : CupertinoColors.activeBlue
                          : CupertinoColors.activeBlue.withOpacity(0.1),
                    ),
                    child: isPinVisible && index < enteredPin.length
                        ? Center(
                      child: Text(
                        enteredPin[index],
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                        : null,
                  );
                },
              ),
            ),

            /// visiblity toggle button
            IconButton(
              onPressed: () {
                setState(() {
                  isPinVisible = !isPinVisible;
                });
              },
              icon: Icon(
                isPinVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),

            SizedBox(height: isPinVisible ? 50.0 : 8.0),

            /// digits
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                        (index) => numButton(1 + 3 * i + index),
                  ).toList(),
                ),
              ),

            /// 0 digit with back remove
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () {
                    setState(() {
                      enteredPin='';
                    });
                  },
                    child: const Text (
                      'Reset',
                      style: TextStyle(
                        fontSize: 18, color: Colors.black,
                      ),
                    ), ) ,
                  //const TextButton(onPressed: null, child: SizedBox()),
                  numButton(0),
                  TextButton(
                    onPressed: () {
                      setState(
                            () {
                          if (enteredPin.isNotEmpty) {
                            enteredPin =
                                enteredPin.substring(0, enteredPin.length - 1);
                          }
                        },
                      );
                    },
                    child: const Icon(
                      Icons.backspace,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            /// ok button

            TextButton(
              onPressed: () {
                verifyPin(); // Appellez la fonction de création du PIN
              },
              child: const Text(
                'Ok',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

