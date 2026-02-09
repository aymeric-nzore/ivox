import 'package:flutter/material.dart';

class MyIconTile extends StatelessWidget {
  final String name;
  final String title;
  final VoidCallback onTap;
  const MyIconTile({super.key, required this.name, required this.onTap, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(30),
          color: colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/$name", height: 30),
            SizedBox(width: 8,),
            Text(
              title,
              style: TextStyle(color: colorScheme.onSurface),
            )
          ],
        ),
      ),
    );
  }
}
