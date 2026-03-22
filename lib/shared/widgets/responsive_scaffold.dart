import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final VoidCallback? onMenuPressed;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: actions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
