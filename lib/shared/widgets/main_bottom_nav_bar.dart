import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
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
            currentIndex: currentIndex,
            onTap: onTap,
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.book),
                title: const Text("Leçons"),
                selectedColor: Colors.amber,
              ),
              SalomonBottomBarItem(
                icon: SvgPicture.asset(
                  isDark
                      ? "assets/icons/trophy-line_white.svg"
                      : "assets/icons/trophy-line.svg",
                ),
                title: const Text("Leaderboard"),
                selectedColor: Colors.amber,
                activeIcon: SvgPicture.asset(
                  "assets/icons/trophy-fill.svg",
                ),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.message_outlined),
                title: const Text("Chat"),
                selectedColor: Colors.amber,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person),
                title: const Text("Profile"),
                selectedColor: Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
