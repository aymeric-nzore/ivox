import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:popover/popover.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? subtitle;
  final String? photoUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddFriend;
  final VoidCallback? onBlockUser;
  const UserTile({
    super.key,
    required this.text,
    this.subtitle,
    this.photoUrl,
    required this.onTap,
    this.onAddFriend,
    this.onBlockUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final addFriendBg =
        isDark ? const Color(0xFF1F3A5F) : const Color(0xFFE8F0FE);
    final addFriendFg =
        isDark ? const Color(0xFFD6E4FF) : const Color(0xFF0D47A1);
    final blockBg =
        isDark ? const Color(0xFF4A2426) : const Color(0xFFFFEBEE);
    final blockFg =
        isDark ? const Color(0xFFFFCDD2) : const Color(0xFFB71C1C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => showPopover(
                height: 96,
                width: 220,
                direction: PopoverDirection.bottom,
                context: context,
                bodyBuilder: (context) => Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.person_add_alt_1,
                        label: 'Ajoutez en amis',
                        color: addFriendBg,
                        foregroundColor: addFriendFg,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          onAddFriend?.call();
                        },
                      ),
                      _ActionRow(
                        icon: Icons.block,
                        label: 'Bloquez cet utilisateur',
                        color: blockBg,
                        foregroundColor: blockFg,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                          onBlockUser?.call();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.35),
          highlightColor: Colors.black.withValues(alpha: 0.08),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
