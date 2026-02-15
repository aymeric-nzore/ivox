import 'package:flutter/material.dart';
import 'package:ivox/features/chat/presentation/list_user_page.dart';
import 'package:ivox/features/leaderboard/leaderboard_page.dart';
import 'package:ivox/features/lessons/presentation/lessons_page.dart';
import 'package:ivox/features/profile/presentation/profile_page.dart';
import 'package:ivox/shared/utils/responsive.dart';

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
    if (Responsive.isMobileOrTablet(context)) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout() {
    return _buildPage();
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final navItems = [
      ('Leçons', Icons.book),
      ('Classement', Icons.leaderboard),
      ('Chat', Icons.message),
      ('Profil', Icons.person),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _handleTabSelected,
            extended: MediaQuery.of(context).size.width > 1200,
            minExtendedWidth: 250,
            destinations: navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.$2),
                    label: Text(item.$1),
                  ),
                )
                .toList(),
          ),
          // Content
          Expanded(
            child: _buildPage(),
          ),
        ],
      ),
    );
  }
}
