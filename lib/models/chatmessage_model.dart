import 'package:flutter/cupertino.dart';

class ChatMessage{
  String messageContent;
  String messageType;
  String date;
  ChatMessage({required this.messageContent, required this.messageType, required this.date});
}