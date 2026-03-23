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
  int _pendingFriendRequests = 0;

  @override
  void initState() {
    super.initState();
    _usersFuture = _chatService.getUsers();
    _syncFriendRequestBadge();
    _appNotificationSubscription = _chatService.appNotifications.listen((notification) {
      if (!mounted) return;
      final type = (notification['type'] ?? '').toString();
      if (type == 'friend_request') {
        final fromUsername =
            (notification['fromUsername'] ?? 'Quelqu\'un').toString();
        setState(() {
          _pendingFriendRequests += 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nouvelle demande d\'ami de $fromUsername')),
        );
      } else if (type == 'friend_request_response') {
        final fromUsername =
            (notification['fromUsername'] ?? 'Utilisateur').toString();
        final action = (notification['action'] ?? 'respond').toString();
        final accepted = action == 'accept';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepted
                  ? '$fromUsername a accepte votre demande d\'ami'
                  : '$fromUsername a refuse votre demande d\'ami',
            ),
          ),
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
    await _syncFriendRequestBadge();
  }

  Future<void> _syncFriendRequestBadge() async {
    try {
      final payload = await _chatService.getFriendRequests();
      final received = payload['received'];
      if (!mounted) return;
      setState(() {
        _pendingFriendRequests = received is List ? received.length : 0;
      });
    } catch (_) {
      // Ignore badge refresh failures and keep existing count.
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

  Future<void> _showFriendsAndRequests() async {
    try {
      final payload = await _chatService.getFriendRequests();
      List<Map<String, dynamic>> received = (payload['received'] as List?)
              ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
              .toList() ??
          <Map<String, dynamic>>[];
      List<Map<String, dynamic>> sent = (payload['sent'] as List?)
              ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
              .toList() ??
          <Map<String, dynamic>>[];
      List<Map<String, dynamic>> friends = (payload['friends'] as List?)
              ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
              .toList() ??
          <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _pendingFriendRequests = received.length;
      });

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: DefaultTabController(
              length: 3,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  Future<void> handleResponse({
                    required String requesterId,
                    required bool accept,
                  }) async {
                    await _chatService.respondFriendRequest(
                      requesterId,
                      accept: accept,
                    );
                    final refreshed = await _chatService.getFriendRequests();
                    received = (refreshed['received'] as List?)
                            ?.map(
                              (e) =>
                                  (e as Map).map((k, v) => MapEntry(k.toString(), v)),
                            )
                            .toList() ??
                        <Map<String, dynamic>>[];
                    sent = (refreshed['sent'] as List?)
                            ?.map(
                              (e) =>
                                  (e as Map).map((k, v) => MapEntry(k.toString(), v)),
                            )
                            .toList() ??
                        <Map<String, dynamic>>[];
                    friends = (refreshed['friends'] as List?)
                            ?.map(
                              (e) =>
                                  (e as Map).map((k, v) => MapEntry(k.toString(), v)),
                            )
                            .toList() ??
                        <Map<String, dynamic>>[];

                    if (!mounted) return;
                    setState(() {
                      _pendingFriendRequests = received.length;
                    });
                    setModalState(() {});
                    await _refreshUsers();
                  }

                  Widget buildAvatar(Map<String, dynamic> item) {
                    final photoUrl = (item['photoUrl'] ?? '').toString();
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                    );
                  }

                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Amis'),
                            Tab(text: 'Recues'),
                            Tab(text: 'Envoyees'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              friends.isEmpty
                                  ? const Center(child: Text('Aucun ami pour le moment'))
                                  : ListView.builder(
                                      itemCount: friends.length,
                                      itemBuilder: (context, index) {
                                        final item = friends[index];
                                        return ListTile(
                                          leading: buildAvatar(item),
                                          title: Text((item['username'] ?? 'Utilisateur').toString()),
                                          subtitle: Text(
                                            ((item['status'] ?? 'offline')
                                                    .toString()
                                                    .toLowerCase() ==
                                                'online')
                                                ? 'En ligne'
                                                : 'Hors ligne',
                                          ),
                                        );
                                      },
                                    ),
                              received.isEmpty
                                  ? const Center(
                                      child: Text('Aucune demande en attente'),
                                    )
                                  : ListView.builder(
                                      itemCount: received.length,
                                      itemBuilder: (context, index) {
                                        final item = received[index];
                                        final requesterId = (item['id'] ?? '').toString();
                                        return ListTile(
                                          leading: buildAvatar(item),
                                          title: Text((item['username'] ?? 'Utilisateur').toString()),
                                          subtitle: Text((item['email'] ?? '').toString()),
                                          trailing: Wrap(
                                            spacing: 4,
                                            children: [
                                              IconButton(
                                                tooltip: 'Refuser',
                                                onPressed: () => handleResponse(
                                                  requesterId: requesterId,
                                                  accept: false,
                                                ),
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Accepter',
                                                onPressed: () => handleResponse(
                                                  requesterId: requesterId,
                                                  accept: true,
                                                ),
                                                icon: const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                              sent.isEmpty
                                  ? const Center(
                                      child: Text('Aucune demande envoyee'),
                                    )
                                  : ListView.builder(
                                      itemCount: sent.length,
                                      itemBuilder: (context, index) {
                                        final item = sent[index];
                                        return ListTile(
                                          leading: buildAvatar(item),
                                          title: Text((item['username'] ?? 'Utilisateur').toString()),
                                          subtitle: const Text('En attente de reponse'),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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

  Future<void> _showBlockedUsers() async {
    try {
      List<ChatUser> blockedUsers = await _chatService.getBlockedUsers();
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                if (blockedUsers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun utilisateur bloque'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = blockedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child: user.photoUrl == null || user.photoUrl!.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          await _chatService.unblockUser(user.id);
                          blockedUsers = await _chatService.getBlockedUsers();
                          setModalState(() {});
                          await _refreshUsers();
                        },
                        child: const Text('Debloquer'),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement bloquees: $e')),
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
              title: _pendingFriendRequests > 0
                  ? "Amis ($_pendingFriendRequests)"
                  : "Amis",
              onTap: () async {
                Navigator.of(context).pop();
                await _showFriendsAndRequests();
              },
            ),
            MyDrawerTile(
              icon: Icon(Icons.block),
              title: "Utilisateurs bloqués",
              onTap: () async {
                Navigator.of(context).pop();
                await _showBlockedUsers();
              },
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
              receiverLastSeen: userData.lastSeen,
            ),
          ),
        );
      },
    );
  }
}
