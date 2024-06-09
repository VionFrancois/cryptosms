import 'package:flutter/material.dart';
import '../screens/chat_detail_page.dart';
import '../models/user_model.dart';

class ChatUsers {
  final String name;
  final String messageText;
  final String imageURL;
  final String time;

  ChatUsers({
    required this.name,
    required this.messageText,
    required this.imageURL,
    required this.time,
  });
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatUsers> chatUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchChatUsers();
  }

  Future<void> _fetchChatUsers() async {
    // Remplacez cette partie par l'appel à votre fonction externe pour récupérer les utilisateurs de chat
    List<ChatUsers> fetchedChatUsers = [
      ChatUsers(
          name: "Jane Russel",
          messageText: "Awesome Setup",
          imageURL: "images/user.jpg",
          time: "Now"),
      ChatUsers(
          name: "Glady's Murphy",
          messageText: "That's Great",
          imageURL: "images/userImage2.jpeg",
          time: "Yesterday"),
      ChatUsers(
          name: "Jorge Henry",
          messageText: "Hey where are you?",
          imageURL: "images/userImage3.jpeg",
          time: "31 Mar"),
      ChatUsers(
          name: "Philip Fox",
          messageText: "Busy! Call me in 20 mins",
          imageURL: "images/userImage4.jpeg",
          time: "28 Mar"),
      ChatUsers(
          name: "Debra Hawkins",
          messageText: "Thank you, It's awesome",
          imageURL: "images/userImage5.jpeg",
          time: "23 Mar"),
      ChatUsers(
          name: "Jacob Pena",
          messageText: "will update you in the evening",
          imageURL: "images/userImage6.jpeg",
          time: "17 Mar"),
    ];

    setState(() {
      chatUsers = fetchedChatUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,  // Désactive le bouton de retour
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                // Suppression de l'icône de retour et ajout de marge
                SizedBox(width: 16),
                Text(
                  "Conversations",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                // Suppression des icônes de recherche et des trois petits points
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListView.builder(
              itemCount: chatUsers.length,
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 16),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return ChatDetailPage();
                    }));
                  },
                  child: Container(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        // Suppression du CircleAvatar
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  chatUsers[index].name,
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  chatUsers[index].messageText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    // fontWeight: chatUsers[index].isMessageRead
                                    //     ? FontWeight.bold
                                    //     : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          chatUsers[index].time,
                          style: TextStyle(
                            fontSize: 12,
                            // fontWeight: chatUsers[index].isMessageRead
                            //     ? FontWeight.bold
                            //     : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
