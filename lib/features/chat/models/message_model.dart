import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderID;
  final String senderEmail;
  final String senderUsername;
  final String receiverID;
  final String message;
  final Timestamp timestamp;

  MessageModel({
    required this.senderID,
    required this.senderEmail,
    required this.senderUsername,
    required this.receiverID,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'senderUsername': senderUsername,
      'receiverID': receiverID,
      'message': message,
      'timestamp': Timestamp.now(),
    };
  }
}
