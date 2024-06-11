import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../back/messages_manager.dart';
import '../screens/messages.dart';
import '../back/db.dart';

String formatElapsedTime(String dateString) {
  DateTime messageDate = DateTime.parse(dateString);
  DateTime now = DateTime.now();
  Duration difference = now.difference(messageDate);

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else {
    return DateFormat('d MMM').format(messageDate);
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Contact> contacts = [];
  Map<String, String> decryptedMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    List<Contact> fetchedContacts = await DatabaseHelper().getAllContacts();

    // Charger les messages et les déchiffrer
    for (var contact in fetchedContacts) {
      if (contact.lastReceivedMessage.isNotEmpty) {
        print(contact.lastReceivedMessage);
        try {
          String decryptedMessage = await readEncryptedMessage(contact, contact.lastReceivedMessage);
          decryptedMessages[contact.phoneNumber] = decryptedMessage;
        } catch (e) {
          print("Erreur de déchiffrement page d'accueil");
        }
      }
    }

    setState(() {
      contacts = fetchedContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchContacts,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              elevation: 0,
              automaticallyImplyLeading: false, // Désactive le bouton de retour
              backgroundColor: Colors.white,
              flexibleSpace: SafeArea(
                child: Container(
                  padding: EdgeInsets.only(right: 16),
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 16),
                      Text(
                        "Conversations",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(contact: contacts[index]),
                        ),
                      );
                      _fetchContacts();
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: contacts[index].seen ? Colors.white : Colors.yellow.withOpacity(0.2),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              color: Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    contacts[index].name,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    decryptedMessages[contacts[index].phoneNumber] ?? "",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            formatElapsedTime(contacts[index].lastReceivedMessageDate),
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: contacts.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
