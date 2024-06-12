import 'package:flutter/material.dart';
import 'dart:async';
import '../back/crypto.dart';
import '../back/db.dart';
import 'new_contact.dart';

class Contacts extends StatefulWidget {
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  // Contacts list to display
  List<Contact> contacts = [];
  List<Contact> searchedContacts = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    searchController.addListener(_searchContacts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    // Verify if there is new keys
    CryptoManager().verifyContactsKeys();
    // Fetches contacts from database
    List<Contact> contacts = await DatabaseHelper().getAllContacts();
    setState(() {
      contacts = contacts;
      searchedContacts = contacts;
    });
  }

  // Search the contacts that satisfy the query
  void _searchContacts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      searchedContacts = contacts.where((contact) {
        return contact.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchContacts,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(), // pour toujours permettre le glissement
          children: <Widget>[

            // Title and "Add new" button area
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Contacts",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),

                  // Add new button
                  GestureDetector(
                    // Action
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return SelectContactPage();
                      }));
                    },

                    // Appearance
                    child: Container(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.orange[50],
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.add,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "Add new",
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

            // Search bar
            Padding(
              padding: EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search",
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

            // Contacts list
            Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: searchedContacts.length,
                itemBuilder: (context, index) {
                  Contact contact = searchedContacts[index];
                  return ListTile(
                    // A line of the list (Name + connexion icon)
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(contact.name),
                        Image.asset(
                          contact.symmetricKey == "" ? 'assets/unconnected.png' : 'assets/connected.png',
                          height: 20,
                          width: 70,
                        ),
                      ],
                    ),
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
