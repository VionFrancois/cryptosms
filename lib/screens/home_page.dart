import 'package:flutter/material.dart';
import '../screens/contacts.dart';
import '../screens/discussions.dart'; // Assurez-vous que ce fichier contient ChatPage
import '../screens/home_page.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    ChatPage(), // Assurez-vous que ChatPage est la bonne classe pour les discussions
    Contacts(), // Assurez-vous que Contacts est la bonne classe pour les contacts
    Text('Profile'), // Remplacez ceci par votre widget de profil réel
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.greenAccent,
      appBar: AppBar(
        //backgroundColor: Colors.lightBlue,
        title: Text("CryptoSMS"),
        // Supprimer les actions pour enlever la loupe et les trois petits points
        actions: [],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            label: 'Discussions',
            icon: Icon(Icons.message),
          ),
          BottomNavigationBarItem(
            label: 'Contacts',
            icon: Icon(Icons.contacts),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: "Profile",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
