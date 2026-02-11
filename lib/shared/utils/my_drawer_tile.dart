import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  final Icon icon;
  final String title;
  final VoidCallback onTap;
  const MyDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: icon, title: Text(title));
  }
}
