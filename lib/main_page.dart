import 'package:flutter/material.dart';
import 'package:ivox/features/chat/presentation/list_user_page.dart';
import 'package:ivox/features/leaderboard/leaderboard_page.dart';
import 'package:ivox/features/lessons/presentation/lessons_page.dart';
import 'package:ivox/features/mylann/presentation/mylann_chat_page.dart';
import 'package:ivox/features/profile/presentation/profile_page.dart';
import 'package:ivox/shared/walkthrough/app_walkthrough_controller.dart';
import 'package:ivox/shared/walkthrough/tutorial_launch_service.dart';

class MainPage extends StatefulWidget {
  final bool startTutorial;

  const MainPage({super.key, this.startTutorial = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final shouldStart = await TutorialLaunchService.instance
          .shouldStartTutorial(requestedByRoute: widget.startTutorial);
      if (!mounted || !shouldStart) return;

      await TutorialLaunchService.instance.markTutorialSeenForCurrentUser();
      AppWalkthroughController.instance.start();
      _handleTabSelected(0);
    });
  }

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
        return MylannChatPage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
      case 3:
        return ListUserPage(
          currentIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        );
      case 4:
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
