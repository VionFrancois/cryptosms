import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart' as contacts_service;
import 'package:permission_handler/permission_handler.dart';
import '../back/db.dart';
import '../back/messages_manager.dart';

class SelectContactPage extends StatefulWidget {
  @override
  _SelectContactPageState createState() => _SelectContactPageState();
}

class _SelectContactPageState extends State<SelectContactPage> {
  List<contacts_service.Contact> _contacts = [];
  contacts_service.Contact? _selectedContact;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (await Permission.contacts.request().isGranted) {
      _fetchContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contacts permission is required to proceed.')),
      );
    }
  }

  Future<void> _fetchContacts() async {
    Iterable<contacts_service.Contact> contacts = await contacts_service.ContactsService.getContacts();
    setState(() {
      _contacts = contacts.toList();
    });
  }

  void _selectContact(contacts_service.Contact contact) {
    setState(() {
      _selectedContact = contact;
    });
    _showConfirmationDialog(contact);
  }

  Future<void> _saveContactToDatabase() async {
    if (_selectedContact != null && _selectedContact!.phones!.isNotEmpty) {
      String phoneNumber = _selectedContact!.phones!.first.value ?? "000000000";
      String name = _selectedContact!.displayName ?? "Contact";

      // Appelle ta méthode pour sauvegarder le contact dans la base de données
      Contact? newContact = await createContact(phoneNumber, name);
      if (newContact != null) {
        initHandshake(newContact);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a contact with a phone number.')),
      );
    }
  }

  void _showConfirmationDialog(contacts_service.Contact contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Contact Addition'),
          content: Text('Do you want to add ${contact.displayName} as a contact? ${contact.displayName} will receive an SMS of invitation'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveContactToDatabase();
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Contact"),
      ),
      body: _contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          contacts_service.Contact contact = _contacts[index];
          return ListTile(
            title: Text(contact.displayName ?? 'No name'),
            subtitle: Text(contact.phones!.isNotEmpty
                ? contact.phones!.first.value ?? 'No phone number'
                : 'No phone number'),
            onTap: () {
              _selectContact(contact);
            },
          );
        },
      ),
    );
  }
}
