import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/chat/presentation/chat_page.dart';
import 'package:ivox/features/chat/services/chat_services.dart';
import 'package:ivox/features/chat/utils/user_tile.dart';
import 'package:ivox/shared/utils/my_drawer_tile.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';
import 'package:ivox/shared/utils/responsive.dart';

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
  final _authService = AuthService();
  final _chatService = ChatServices();
  bool _isDrawerOpened = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobileOrTablet(context);

    return Scaffold(
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpened = isOpened;
        });
      },
      drawer: isMobile
          ? Drawer(
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
            )
          : null,
      bottomNavigationBar: isMobile && !_isDrawerOpened
          ? MainBottomNavBar(
              currentIndex: widget.currentIndex,
              onTap: widget.onTabSelected,
            )
          : null,
      appBar: AppBar(
        title: Text("Chat"),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Sidebar sur desktop
          if (!isMobile)
            Container(
              width: 250,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Messages",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Expanded(
                    child: _buildUsersList(),
                  ),
                ],
              ),
            ),
          // Contenu principal
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder(
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
