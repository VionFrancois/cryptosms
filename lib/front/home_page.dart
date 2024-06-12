import 'package:flutter/material.dart';
import '../front/contacts.dart';
import 'discussions.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // List with the pages
  static List<Widget> _widgetOptions = <Widget>[
    ChatPage(),
    Contacts(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Logo and application name on top of the pages
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/icon.png',
              height: 40,
            ),
            SizedBox(width: 10),
            Text("CryptoSMS"),
          ],
        ),
        actions: [],
      ),

      // The body is the content of ChatPage() or Contacts()
      body: _widgetOptions.elementAt(_selectedIndex),

      // Bottom navigation bar to navigate between contacts and discussions
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orangeAccent,
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
          )
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
