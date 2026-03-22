import 'package:flutter/material.dart';
import 'package:ivox/features/chat/presentation/list_user_page.dart';
import 'package:ivox/features/leaderboard/leaderboard_page.dart';
import 'package:ivox/features/lessons/presentation/lessons_page.dart';
import 'package:ivox/features/profile/presentation/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  void _handleTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return LessonsPage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
      case 1:
        return LeaderboardPage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
      case 2:
        return ListUserPage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
      case 3:
        return ProfilePage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
      default:
        return LessonsPage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }
}
