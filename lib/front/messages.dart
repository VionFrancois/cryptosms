import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../back/db.dart';
import '../back/crypto.dart';
import '../back/sms_manager.dart';

// This object represents a message in the conversation
class ChatMessage{
  String messageContent;
  String messageType;
  String date;
  ChatMessage({required this.messageContent, required this.messageType, required this.date});
}

class ChatDetailPage extends StatefulWidget {
  final Contact contact;

  ChatDetailPage({required this.contact});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  // The list of messages for the conversation
  List<ChatMessage> messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // At initialisation, we fetch the messages from device
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      // Fetches messages
      List<List<dynamic>> fetchedConversation = await SMSManager().fetchConversation(widget.contact);

      if (fetchedConversation.isNotEmpty) {
        // Converts the list from SMSManager to a list of ChatMessage objects
        List<ChatMessage> fetchedMessages = fetchedConversation.map((tuple) {
          String messageContent = tuple[0] as String;
          bool isReceived = tuple[1] as bool;
          String date = DateFormat('HH:mm').format(tuple[2] as DateTime);
          return ChatMessage(
              messageContent: messageContent,
              messageType: isReceived ? "receiver" : "sender",
              date: date
          );
        }).toList();

        // Update the list of message with the fetched one
        setState(() {
          messages = fetchedMessages;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) {
      print('Error while fetching messages : $e');
    }

    // When the messages are fetched, the page is opened and we can consider the messages as seen
    DatabaseHelper().messageSeen(widget.contact.phoneNumber);
  }

  // Method called when the send button is pressed
  void _sendMessage() async {
    String message = _messageController.text;

    if (message.isNotEmpty) {
      try {
        // Sends the message encrypted with the contact key
        CryptoManager().sendEncryptedMessage(widget.contact, message);

        setState(() {
          // Adds the message to the list
          String formattedDate = DateFormat('HH:mm').format(DateTime.now());
          messages.add(ChatMessage(messageContent: message, messageType: "sender", date: formattedDate));
          _messageController.clear();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      } catch (e) {
        print('Error while sending a message : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                // Back button
                IconButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Contact name
                      Text(
                        widget.contact.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Content of the conversation
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 60),
            // ListView of the messages
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),

                  // Alignment that depends on the message type
                  child: Align(
                    alignment: (messages[index].messageType == "receiver"
                        ? Alignment.topLeft
                        : Alignment.topRight),
                    // Color that depends on the message type
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: (messages[index].messageType == "receiver"
                            ? Colors.grey.shade200
                            : Colors.blue[200]),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Content of the message
                          Text(
                            messages[index].messageContent,
                            style: TextStyle(fontSize: 15),
                          ),
                          SizedBox(height: 5),
                          // Hour of the message
                          Text(
                            messages[index].date,
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom bar (writing message)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  // Padding at the left
                  SizedBox(width: 10),
                  // Write message input box
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Write message",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // Padding at right and send button
                  SizedBox(width: 15),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}