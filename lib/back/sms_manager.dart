import 'dart:async';
import 'package:flutter_sms/flutter_sms.dart' as flutter_sms;
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'db.dart';
import 'crypto.dart';

// This class manages the SMS operations (sending/receiving),
// the automatic fetching of new incoming messages and the conversations fetching
class SMSManager {
  Timer? _timer;
  final DatabaseHelper db = DatabaseHelper();

  // Verifies new incoming cSMS and new contact keys every 5 seconds
  void startMonitoring() {
    const period = Duration(seconds: 5);
    _timer = Timer.periodic(period, (Timer t) {
      checkForNewSMS();
      CryptoManager().verifyContactsKeys();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  // Basic method for sending SMS with flutter_sms
  Future<void> sendSMS(String message, String phoneNumber) async {
    final recipients = ["+${phoneNumber}"];
    try {
      await flutter_sms.sendSMS(message: message, recipients: recipients, sendDirect: true);
    } catch (e) {
      print('Error while sending the SMS : ${message} ($e)');
    }
  }

  // Basic method for reading SMS with flutter_sms_inbox
  Future<List<SmsMessage>?> getReceivedSMS(String address) async {
    try {
      List<SmsMessage> messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox], address: address);
      return messages;
    } catch (e) {
      print('Error while retrieving SMS $e');
    }
    return null;
  }

  // Verifies if a new cSMS message has been received since the last one
  Future<List<Contact>?> checkForNewSMS() async {
    List<String> recentAddresses = [];
    List<Contact> recentContacts = [];

    try {
      // Make the query only small parts of the SMS inbox
      int start = 0;
      int count = 50;
      // TODO : Filter messages only coming from cSMS contacts for more privacy ?
      List<SmsMessage> messages = await SmsQuery().querySms(kinds: [SmsQueryKind.inbox], start: start, count: count);

      // Retrieve the last cSMS message date from database
      String? lastMessageDateString = await db.getLastReceivedMessageDate();
      DateTime? lastMessageDate = DateTime.tryParse(lastMessageDateString ?? '');

      if (lastMessageDate != null) {
        int i = 0;

        // We will iterate though all the SMS of a user until the last cSMS message date is exceeded
        // We will then lists all the contact that have sent cSMS message in this interval
        while (i < messages.length && messages[i].date != null && lastMessageDate.isBefore(messages[i].date!)) {
          // If it is a cSMS message
          if (messages[i].body != null && CryptoManager().checkHeader(messages[i].body!)[0]) {
            String? address = messages[i].address;
            if (address != null) {
              // If the contact has not been listed yet
              if (!recentAddresses.contains(address)) {
                recentAddresses.add(address);
                // Warns the database that the user have unseen messages from this contact
                await db.newMessage(address, messages[i].body!, messages[i].date!, false);
              }
            }
          }

          i++;
          if (i == count) {
            // Query with the next 50 SMS
            start += count;
            count += count;
            messages = await SmsQuery().querySms(start: start, count: count);
            i = 0;
          }
        }
      }
    } catch (e) {
      print('Error while checking for new SMS : $e');
    }

    // Converts the addresses into Contact objects
    if (recentAddresses.isNotEmpty) {
      for (String address in recentAddresses) {
          Contact? contact = await db.getContact(address);
          if (contact != null) {
            recentContacts.add(contact);
          }
      }
      return recentContacts;
    }
    return null;
  }

  // Fetch all the conversation between a user and a contact
  Future<List<List<dynamic>>> fetchConversation(Contact contact) async {
    List<List<dynamic>> conversation = [];

    try {
      // Query all the SMS from/to a contact
      List<SmsMessage> messages = await SmsQuery().querySms(
        kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
        address: contact.phoneNumber,
      );

      // We go through all the messages and create a list in a right format
      for (var message in messages) {
        var content = message.body!;
        List<bool> header = CryptoManager().checkHeader(content);

        // If it is a cSMS message (and not key exchange)
        if (header[0] && !header[1]) {
          // Decrypts the message using the contact object (and therefore keys)
          String? decryptedMessage;
          try{
            decryptedMessage = await CryptoManager().readEncryptedMessage(contact, content);
            bool isReceived = message.kind == SmsMessageKind.received;

            conversation.add([decryptedMessage, isReceived, message.date]);
          }
          catch(e){
            print("Error while decrypting a message with valid header");
          }
        }
      }
    } catch (e) {
      print('Error while fetching conversation : $e');
    }

    // Sorts the messages by their date
    conversation.sort((a, b) => a[2].compareTo(b[2])); // a[2] et b[2] are dates

    return conversation;
  }
}
