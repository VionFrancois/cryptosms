import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
//import '../service/databasecontact.dart';
import '../screens/new_contact.dart';
import 'new_contact.dart';
//import '../widgets/conversation_list.dart';
import '../back/db.dart';

// TODO : Dessin de chaine dans la liste des contacts en fonction de l'échange de clés ?

class Contacts extends StatefulWidget {
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts>{
  // Liste de contacts pour l'affichage
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    List<Contact> contacts = await DatabaseHelper().getAllContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Contacts",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return SelectContactPage();
                        }));
                      },
                      child: Container(
                        padding: EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.pink[50],
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.add,
                              color: Colors.pink,
                              size: 20,
                            ),
                            SizedBox(
                              width: 2,
                            ),
                            Text(
                              "Add New",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade100)),
                ),
              ),
            ),
            // Afficher la liste des contacts
            Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                shrinkWrap: true, // Important to make ListView inside SingleChildScrollView
                physics: NeverScrollableScrollPhysics(), // Disable ListView scrolling
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  Contact contact = _contacts[index];
                  return ListTile(
                    title: Text(contact.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
