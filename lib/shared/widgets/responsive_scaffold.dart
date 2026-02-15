import 'package:flutter/material.dart';
import 'package:ivox/shared/utils/responsive.dart';

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
    final isMobile = Responsive.isMobileOrTablet(context);
    final maxWidth = Responsive.getMaxWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: actions,
      ),
      body: Center(
        child: SizedBox(
          width: isMobile ? maxWidth : maxWidth,
          child: Padding(
            padding: Responsive.getPadding(context),
            child: child,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
