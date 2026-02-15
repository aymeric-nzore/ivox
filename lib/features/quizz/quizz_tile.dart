import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class QuizzTile extends StatelessWidget {
  final String title;
  final String desc;
  final String times;
  final String imagePath;
  final VoidCallback onTap;
  final Color bgColor;
  final double progress;
  const QuizzTile({
    super.key,
    required this.title,
    required this.desc,
    required this.times,
    required this.imagePath,
    required this.onTap,
    required this.bgColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final double maxWidth = 160;
    final double progressWidth = maxWidth * progress.clamp(0.0, 1.0);
    final int percent = (progress.clamp(0.0, 1.0) * 100).round();
    final String completedLabel =
        percent >= 100 ? "Completed" : "Completed $percent%";
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 18,
                spreadRadius: -2,
                offset: Offset(0, 10),
              ),
            ],
          ),
          constraints: const BoxConstraints(minHeight: 170),
          padding: const EdgeInsets.symmetric(horizontal: 16,),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(imagePath, height: 120),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      softWrap: true,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      softWrap: true,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      spacing: 6,
                      children: [
                        Icon(Icons.timelapse, color: Colors.blue, size: 16),
                        Text(
                          times,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      completedLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    //Progress
                    Stack(
                      children: [
                        SizedBox(
                          height: 7,
                          width: maxWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 7,
                          width: progressWidth,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
