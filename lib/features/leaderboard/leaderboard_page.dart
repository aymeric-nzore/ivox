import 'package:flutter/material.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';

class LeaderboardPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const LeaderboardPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leadboard"),
        centerTitle: true,
        leading: Text(""),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
    );
  }
}
