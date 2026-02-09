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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Image
              LottieBuilder.asset(imageAssets, height: 400),
              //title
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              //description
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
