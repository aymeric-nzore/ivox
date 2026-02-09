import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/chat/presentation/chat_page.dart';
import 'package:ivox/features/chat/services/chat_services.dart';
import 'package:ivox/features/chat/utils/user_tile.dart';

class ListUserPage extends StatefulWidget {
  const ListUserPage({super.key});

  @override
  State<ListUserPage> createState() => _ListUserPageState();
}

class _ListUserPageState extends State<ListUserPage> {
  final _authService = AuthService();
  final _chatService = ChatServices();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat"), centerTitle: true, leading: Text("")),
      body: StreamBuilder(
        stream: _chatService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          return ListView(
            children: snapshot.data!
                .map((userData) => _buildUserList(userData, context))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildUserList(Map<String, dynamic> userData, BuildContext context) {
    if (userData["email"] != _authService.getUser()!.email) {
      return UserTile(
        text: userData["username"],
        photoUrl: userData["photoUrl"],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: userData["username"],
                receiverID: userData["uid"],
                receiverPhotoUrl: userData["photoUrl"],
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }
}
