import 'package:flutter/material.dart';
import '../screens/contacts.dart';
import '../screens/discussions.dart';
import '../screens/home_page.dart';

class MyHomePage extends StatefulWidget{
  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
int _selectedIndex =0;
static List<Widget> _widgetOptions = <Widget>[
  Text('Discussions'),
  Text('Contacts'),
  Text('profile'),
];
void _onItemtapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
  if (index ==1) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Contacts()),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      //backgroundColor: Colors.greenAccent,
      appBar: AppBar(
        //backgroundColor: Colors.lightBlue,
        title: Text("CryptoSMS"),
        actions: [Icon(Icons.search), Icon(Icons.more_vert)],
      ),
      body: ChatPage(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              label: ('Discussions'), icon: Icon(Icons.message)),

          BottomNavigationBarItem(
            label: ('Contacts'),
            icon: Icon(Icons.contacts),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: ("Profile"),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemtapped,


      ),

    );
  }
}
