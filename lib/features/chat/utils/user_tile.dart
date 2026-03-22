import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:popover/popover.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? photoUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddFriend;
  final VoidCallback? onBlockUser;
  const UserTile({
    super.key,
    required this.text,
    this.photoUrl,
    required this.onTap,
    this.onAddFriend,
    this.onBlockUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              child: Text(
                text,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => showPopover(
                height: 96,
                width: 220,
                direction: PopoverDirection.bottom,
                context: context,
                bodyBuilder: (context) => Column(
                  children: [
                    _ActionRow(
                      icon: Icons.person_add_alt_1,
                      label: 'Ajoutez en amis',
                      color: Colors.blue.shade200,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        onAddFriend?.call();
                      },
                    ),
                    _ActionRow(
                      icon: Icons.block,
                      label: 'Bloquez cet utilisateur',
                      color: Colors.red.shade300,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        onBlockUser?.call();
                      },
                    ),
                  ],
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
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
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
              Icon(icon),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
