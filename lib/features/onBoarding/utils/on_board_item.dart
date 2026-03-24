import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnBoardItem extends StatelessWidget {
  final String imageAssets;
  final String title;
  final String description;
  final Color textColor;
  const OnBoardItem({
    super.key,
    required this.imageAssets,
    required this.title,
    required this.description,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 360;
        final animHeight = isSmall
            ? 220.0
            : width < 700
                ? 320.0
                : 400.0;

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LottieBuilder.asset(imageAssets, height: animHeight),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 21 : 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
