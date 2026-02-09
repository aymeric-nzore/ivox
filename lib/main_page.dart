import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ivox/features/chat/presentation/list_user_page.dart';
import 'package:ivox/features/leaderboard/leaderboard_page.dart';
import 'package:ivox/features/lessons/presentation/lessons_page.dart';
import 'package:ivox/features/profile/presentation/profile_page.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> _pages = [
    LessonsPage(),
    LeaderboardPage(),
    ListUserPage(),
    ProfilePage(),
  ];
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.95)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SalomonBottomBar(
              margin: const EdgeInsets.all(12),
              duration: const Duration(milliseconds: 600),
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
              items: [
                SalomonBottomBarItem(
                  icon: Icon(Icons.book),
                  title: Text("Leçons"),
                  selectedColor: Colors.amber,
                ),
                SalomonBottomBarItem(
                  icon: SvgPicture.asset(
                    isDark
                        ? "assets/icons/trophy-line_white.svg"
                        : "assets/icons/trophy-line.svg",
                  ),
                  title: Text("Leaderboard"),
                  selectedColor: Colors.amber,
                  activeIcon: SvgPicture.asset("assets/icons/trophy-fill.svg"),
                ),
                SalomonBottomBarItem(
                  icon: Icon(Icons.message_outlined),
                  title: Text("Chat"),
                  selectedColor: Colors.amber,
                ),
                SalomonBottomBarItem(
                  icon: Icon(Icons.person),
                  title: Text("Profile"),
                  selectedColor: Colors.amber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
