import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart' as contacts_service;
import 'package:permission_handler/permission_handler.dart';
import '../back/db.dart';
import '../back/crypto.dart';
import '../back/sms_manager.dart';

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

  // Requests permissions for contact's access
  Future<void> _requestPermission() async {
    if (await Permission.contacts.request().isGranted) {
      _fetchContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contacts permission is required to proceed.')),
      );
    }
  }

  // Fetch all the device's contacts using contacts_service library
  Future<void> _fetchContacts() async {
    Iterable<contacts_service.Contact> contactsList = await contacts_service.ContactsService.getContacts();
    setState(() {
      contacts = contactsList.toList();
      searchedContacts = contacts;
    });
  }

  // Search the contacts that satisfy the query
  void _searchContacts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      searchedContacts = contacts.where((contact) {
        return (contact.displayName ?? '').toLowerCase().contains(query) ||
            (contact.phones?.any((phone) => phone.value?.contains(query) ?? false) ?? false);
      }).toList();
    });
  }

  // Method executed when we tap on a contact
  void _selectContact(contacts_service.Contact contact) {
    setState(() {
      selectedContact = contact;
    });
    if (selectedContact != null && selectedContact!.phones!.isNotEmpty) {
      if (selectedContact!.phones!.first.value != null){
        String? phoneNumber = selectedContact!.phones!.first.value;
        // If the number starts with 0, we have to ask the user what prefix it is
        if (phoneNumber!.startsWith("0")) {
          _showPrefixDialog(phoneNumber);
        } else {
          _showConfirmationDialog(contact.displayName ?? "Contact", contact.phones!.first.value!);
        }
      }
    }
  }

  Future<void> _saveContactToDatabase(String phoneNumber, String name) async {
    Contact? newContact = await CryptoManager().createContact(phoneNumber, name);

    if (newContact != null) {
      // We verify if it's contact has already sent us a key
      String? key = await CryptoManager().fetchKey(newContact.phoneNumber);
      if (key != null) {
        // Only send our key as it is done in initHandshake
        var keyMessage = "cSMS key : ${newContact.publicKey}";
        SMSManager().sendSMS(keyMessage, newContact.phoneNumber);
        // Complete the handshake with both keys
        CryptoManager().completeHandshake(newContact, key);
      } else{
        // If the contact didn't sent us a key, we
        CryptoManager().initHandshake(newContact);
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create contact.')),
      );
    }
  }

  // Pop up for choosing a prefix
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
                  // Prefix + the phone number without the 0
                  String updatedPhoneNumber = prefix + phoneNumber.substring(1);
                  String name = selectedContact!.displayName ?? "Contact";
                  Navigator.of(context).pop();
                  // Opens the pop up for confirmation with the new phone number
                  _showConfirmationDialog(name, updatedPhoneNumber);
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

  // Pop up for asking confirmation of inviting new contact
  void _showConfirmationDialog(String name, String phoneNumber) {
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
                // Starts the contact addition process
                _saveContactToDatabase(phoneNumber, name);
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
          // Search bar
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

          // Content (list of contacts)
          Expanded(
            child: searchedContacts.isEmpty
                ? Center(child: CircularProgressIndicator()) // Circular loading while no content
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
