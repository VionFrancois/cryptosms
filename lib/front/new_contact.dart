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
  List<contacts_service.Contact> contacts = [];
  List<contacts_service.Contact> searchedContacts = [];
  contacts_service.Contact? selectedContact;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermission();
    searchController.addListener(_searchContacts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
    Iterable<contacts_service.Contact> contactsList = await contacts_service.ContactsService.getContacts();
    setState(() {
      contacts = contactsList.toList();
      searchedContacts = contacts;
    });
  }

  void _searchContacts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      searchedContacts = contacts.where((contact) {
        return (contact.displayName ?? '').toLowerCase().contains(query) ||
            (contact.phones?.any((phone) => phone.value?.contains(query) ?? false) ?? false);
      }).toList();
    });
  }

  void _selectContact(contacts_service.Contact contact) {
    setState(() {
      selectedContact = contact;
    });
    if (selectedContact != null && selectedContact!.phones!.isNotEmpty) {
      if (selectedContact!.phones!.first.value != null){
        String? phoneNumber = selectedContact!.phones!.first.value;
        if (phoneNumber!.startsWith("0")) {
          _showPrefixDialog(phoneNumber);
        } else {
          _showConfirmationDialog(contact);
        }
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
                  String name = selectedContact!.displayName ?? "Contact";
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
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
                  borderSide: BorderSide(color: Colors.grey.shade100),
                ),
              ),
            ),
          ),
          Expanded(
            child: searchedContacts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: searchedContacts.length,
              itemBuilder: (context, index) {
                contacts_service.Contact contact = searchedContacts[index];
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
          ),
        ],
      ),
    );
  }
}
