import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';

class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Lessons"),
        leading: Text(""),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: StreamBuilder(
              stream: _authService.userDocStream(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final photoUrl = data?['photoUrl'] as String?;

                return CircleAvatar(
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(Icons.person)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Recherchez des cours...",
                prefixIcon: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.search),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
