import 'package:flutter/material.dart';

class QuizzTileData {
  final String title;
  final String desc;
  final String times;
  final String imagePath;
  final VoidCallback onTap;
  final Color bgColor;
  final double progress;

  QuizzTileData({
    required this.title,
    required this.desc,
    required this.times,
    required this.imagePath,
    required this.onTap,
    required this.bgColor,
    required this.progress,
  });
}
