import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/chat/presentation/chat_page.dart';
import 'package:ivox/features/chat/services/chat_services.dart';
import 'package:ivox/features/chat/utils/user_tile.dart';
import 'package:ivox/shared/utils/my_drawer_tile.dart';

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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                spacing: 15,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.message, size: 32), Text("CHAT")],
              ),
            ),
            MyDrawerTile(
              icon: Icon(Icons.list_alt),
              title: "Listes d'utilisateurs",
              onTap: (){},
            ),
            MyDrawerTile(
              icon: Icon(Icons.person_sharp),
              title: "Amis",
              onTap: (){},
            ),
            MyDrawerTile(
              icon: Icon(Icons.block),
              title: "Utilisateurs bloqués",
              onTap: (){},
            ),
          ],
        ),
      ),
      appBar: AppBar(title: Text("Chat"), centerTitle: true),
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
