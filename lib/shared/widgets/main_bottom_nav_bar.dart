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
    final backgroundColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.96)
        : colorScheme.surface;

    return SafeArea(
      child: SizedBox(
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: CustomPaint(
                painter: _NotchedNavPainter(
                  color: backgroundColor,
                  shadowColor: Colors.black.withValues(
                    alpha: isDark ? 0.2 : 0.12,
                  ),
                ),
                child: SizedBox(
                  height: 74,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SalomonBottomBar(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      duration: const Duration(milliseconds: 600),
                      currentIndex: currentIndex,
                      onTap: onTap,
                      items: [
                        SalomonBottomBarItem(
                          icon: const Icon(Icons.book_outlined),
                          activeIcon: const Icon(Icons.book),
                          title: const Text("Lecons"),
                          selectedColor: Colors.amber,
                        ),
                        SalomonBottomBarItem(
                          icon: SvgPicture.asset(
                            isDark
                                ? "assets/icons/trophy-line_white.svg"
                                : "assets/icons/trophy-line.svg",
                            width: 22,
                            height: 22,
                          ),
                          activeIcon: SvgPicture.asset(
                            "assets/icons/trophy-fill.svg",
                            width: 22,
                            height: 22,
                          ),
                          title: const Text("Leaderboard"),
                          selectedColor: Colors.amber,
                        ),
                        SalomonBottomBarItem(
                          icon: const SizedBox(width: 24, height: 24),
                          activeIcon: const SizedBox(width: 24, height: 24),
                          title: const Text(""),
                          selectedColor: Colors.transparent,
                        ),
                        SalomonBottomBarItem(
                          icon: const Icon(Icons.forum_outlined),
                          activeIcon: const Icon(Icons.forum),
                          title: const Text("Chat"),
                          selectedColor: Colors.amber,
                        ),
                        SalomonBottomBarItem(
                          icon: const Icon(Icons.person_outline),
                          activeIcon: const Icon(Icons.person),
                          title: const Text("Profile"),
                          selectedColor: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: currentIndex == 2
                          ? const [Color(0xFFFFD54F), Color(0xFFF57F17)]
                          : const [Color(0xFFFFE082), Color(0xFFF9A825)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9A825).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(height: 1),
                      Text(
                        'IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchedNavPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  const _NotchedNavPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const double radius = 28;
    const double notchDepth = 20;
    const double cornerRadius = 28;
    final double center = size.width / 2;

    path.moveTo(cornerRadius, 0);
    path.lineTo(center - radius - 16, 0);
    path.quadraticBezierTo(center - radius, 0, center - radius + 2, 6);
    path.arcToPoint(
      Offset(center + radius - 2, 6),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    path.quadraticBezierTo(center + radius, 0, center + radius + 16, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.close();

    canvas.drawShadow(
      path.shift(Offset(0, notchDepth / 2)),
      shadowColor,
      12,
      false,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NotchedNavPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
