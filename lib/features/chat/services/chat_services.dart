import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:ivox/features/chat/models/message_model.dart';

class ChatServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Recup les users
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final user = doc.data();
            return user;
          })
          .where((user) {
            return user['uid'] != _auth.currentUser?.uid;
          })
          .toList();
    });
  }

  //envoyer un message
  Future<void> sendMessage(String receiverID, String message) async {
    final currentUserID = _auth.currentUser!.uid;
    final currentUserEmail = _auth.currentUser!.email!;
    final currentUserDoc =
      await _firestore.collection('users').doc(currentUserID).get();
    final currentUsername =
      (currentUserDoc.data()?['username'] as String?)?.trim();
    final senderName = (currentUsername != null && currentUsername.isNotEmpty)
      ? currentUsername
      : currentUserEmail;

    MessageModel newMessage = MessageModel(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      senderUsername: senderName,
      receiverID: receiverID,
      message: message,
      timestamp: Timestamp.now(),
    );

    //Créer la salle
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    //envoyez à firestore
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("message")
        .add(newMessage.toMap());

      

    // Envoyer la notification via FCM server sans bloquer l'envoi du message
    unawaited(_sendNotificationToServer(receiverID, senderName, message));
  }

  //Envoyer une notification via le serveur FCM
  Future<void> _sendNotificationToServer(
    String receiverID,
    String senderName,
    String message,
  ) async {
    try {
      // Récupérer le token FCM du destinataire depuis Firestore
      final receiverDoc =
          await _firestore.collection('users').doc(receiverID).get();
      final fcmToken = receiverDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('Token FCM non disponible pour le destinataire');
        return;
      }

      final response = await http.post(
        Uri.parse('https://fcm-server-b961.onrender.com/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': 'Nouveau message de $senderName',
          'body': message,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Notification envoyée avec succès');
      } else {
        print('Erreur FCM: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  //get les messages
  Stream<QuerySnapshot> getMessages(String userID, String otherID) {
    //Créer la salle
    List<String> ids = [userID, otherID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("message")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
