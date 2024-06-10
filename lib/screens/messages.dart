import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chatmessage_model.dart';
import '../back/db.dart';
import '../back/messages_manager.dart';

class ChatDetailPage extends StatefulWidget {
  final Contact contact;

  ChatDetailPage({required this.contact});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<ChatMessage> messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      List<List<dynamic>> fetchedConversation = await fetchConversation(widget.contact);
      if (fetchedConversation.isNotEmpty) {
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
        setState(() {
          messages = fetchedMessages;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des messages: $e');
    }
  }

  void _sendMessage() async {
    String message = _messageController.text;
    if (message.isNotEmpty) {
      try {
        sendEncryptedMessage(widget.contact, message);
        setState(() {
          String formattedDate = DateFormat('HH:mm').format(DateTime.now());
          messages.add(ChatMessage(messageContent: message, messageType: "sender", date: formattedDate));
          _messageController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      } catch (e) {
        print('Erreur lors de l\'envoi du message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
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
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 60), // Adjust padding to avoid floating button overlap
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: EdgeInsets.only(top: 10, bottom: 10),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                  child: Align(
                    alignment: (messages[index].messageType == "receiver"
                        ? Alignment.topLeft
                        : Alignment.topRight),
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
                          Text(
                            messages[index].messageContent,
                            style: TextStyle(fontSize: 15),
                          ),
                          SizedBox(height: 5),
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
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Write message...",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
