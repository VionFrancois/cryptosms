import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart' as contacts_service;
import 'package:permission_handler/permission_handler.dart';
import '../back/db.dart';
import '../back/crypto.dart';

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
    if (_selectedContact != null && _selectedContact!.phones!.isNotEmpty) {
      String phoneNumber = _selectedContact!.phones!.first.value ?? "000000000";
      if (phoneNumber.startsWith("0")) {
        _showPrefixDialog(phoneNumber);
      } else {
        _showConfirmationDialog(contact);
      }
    }
  }

  Future<void> _saveContactToDatabase(String phoneNumber, String name) async {
    // TODO : Vérif ici si on a pas déjà reçu une clé ? Si oui, ne pas init mais juste fetch
    Contact? newContact = await CryptoManager().createContact(phoneNumber, name);
    if (newContact != null) {
      CryptoManager().initHandshake(newContact);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create contact.')),
      );
    }
  }

  void _showPrefixDialog(String phoneNumber) {
    TextEditingController _prefixController = TextEditingController(text: "+");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter International Prefix'),
          content: TextField(
            controller: _prefixController,
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String prefix = _prefixController.text;
                if (prefix.isNotEmpty && prefix.startsWith("+")) {
                  String updatedPhoneNumber = prefix + phoneNumber.substring(1);
                  String name = _selectedContact!.displayName ?? "Contact";
                  Navigator.of(context).pop();
                  _showConfirmationDialogWithUpdatedNumber(name, updatedPhoneNumber);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid international prefix.')),
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialogWithUpdatedNumber(String name, String updatedPhoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Contact Addition'),
          content: Text('Do you want to add $name as a contact? $name will receive an SMS of invitation.'),
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
                _saveContactToDatabase(updatedPhoneNumber, name);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(contacts_service.Contact contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Contact Addition'),
          content: Text('Do you want to add ${contact.displayName} as a contact? ${contact.displayName} will receive an SMS of invitation.'),
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
                _saveContactToDatabase(contact.phones!.first.value!, contact.displayName ?? "Contact");
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
