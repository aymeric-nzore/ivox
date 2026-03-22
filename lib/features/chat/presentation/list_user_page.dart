import 'package:flutter/material.dart';
import 'package:ivox/features/chat/presentation/chat_page.dart';
import 'package:ivox/features/chat/services/chat_services.dart';
import 'package:ivox/features/chat/utils/user_tile.dart';
import 'package:ivox/shared/utils/my_drawer_tile.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';

class ListUserPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ListUserPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<ListUserPage> createState() => _ListUserPageState();
}

class _ListUserPageState extends State<ListUserPage> {
  final _chatService = ChatServices();
  bool _isDrawerOpened = false;
  late Future<List<ChatUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _chatService.getUsers();
  }

  Future<void> _refreshUsers() async {
    final users = await _chatService.getUsers();
    if (mounted) {
      setState(() {
        _usersFuture = Future.value(users);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpened = isOpened;
        });
      },
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
              onTap: () {},
            ),
            MyDrawerTile(
              icon: Icon(Icons.person_sharp),
              title: "Amis",
              onTap: () {},
            ),
            MyDrawerTile(
              icon: Icon(Icons.block),
              title: "Utilisateurs bloqués",
              onTap: () {},
            ),
          ],
        ),
      ),
      bottomNavigationBar: !_isDrawerOpened
          ? MainBottomNavBar(
              currentIndex: widget.currentIndex,
              onTap: widget.onTabSelected,
            )
          : null,
      appBar: AppBar(
        title: Text("Chat"),
        centerTitle: true,
      ),
      body: _buildUsersList(context),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return FutureBuilder<List<ChatUser>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Erreur"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? <ChatUser>[];
        return RefreshIndicator(
          onRefresh: _refreshUsers,
          child: ListView(
            children: users
                .map((userData) => _buildUserList(userData, context))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildUserList(ChatUser userData, BuildContext context) {
    return UserTile(
      text: userData.username,
      photoUrl: userData.photoUrl,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: userData.username,
              receiverID: userData.id,
              receiverPhotoUrl: userData.photoUrl,
              receiverStatus: userData.status,
            ),
          ),
        );
      },
    );
  }
}
