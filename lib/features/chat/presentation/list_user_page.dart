import 'package:flutter/material.dart';
import 'dart:async';
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
  StreamSubscription<Map<String, dynamic>>? _appNotificationSubscription;

  @override
  void initState() {
    super.initState();
    _usersFuture = _chatService.getUsers();
    _appNotificationSubscription = _chatService.appNotifications.listen((notification) {
      if (!mounted) return;
      final type = (notification['type'] ?? '').toString();
      if (type == 'friend_request') {
        final fromUsername =
            (notification['fromUsername'] ?? 'Quelqu\'un').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nouvelle demande d\'ami de $fromUsername')),
        );
      }
    });
  }

  @override
  void dispose() {
    _appNotificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    final users = await _chatService.getUsers();
    if (mounted) {
      setState(() {
        _usersFuture = Future.value(users);
      });
    }
  }

  Future<void> _sendFriendRequest(ChatUser user) async {
    try {
      await _chatService.sendFriendRequest(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demande envoyee a ${user.username}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur demande d\'ami: $e')),
        );
      }
    }
  }

  Future<void> _blockUser(ChatUser user) async {
    try {
      await _chatService.blockUser(user.id);
      await _refreshUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} bloque')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur blocage: $e')),
        );
      }
    }
  }

  Future<void> _showFriendRequests() async {
    try {
      final payload = await _chatService.getFriendRequests();
      final received = (payload['received'] as List?)
              ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
              .toList() ??
          <Map<String, dynamic>>[];

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          if (received.isEmpty) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune demande d\'ami en attente'),
              ),
            );
          }

          return SafeArea(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: received.length,
              itemBuilder: (context, index) {
                final item = received[index];
                final requesterId = (item['id'] ?? '').toString();
                final username = (item['username'] ?? 'Utilisateur').toString();

                return ListTile(
                  title: Text(username),
                  subtitle: Text((item['email'] ?? '').toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _chatService.respondFriendRequest(
                            requesterId,
                            accept: false,
                          );
                          navigator.pop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _chatService.respondFriendRequest(
                            requesterId,
                            accept: true,
                          );
                          navigator.pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement demandes: $e')),
        );
      }
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
              onTap: _showFriendRequests,
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
      onAddFriend: () => _sendFriendRequest(userData),
      onBlockUser: () => _blockUser(userData),
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
