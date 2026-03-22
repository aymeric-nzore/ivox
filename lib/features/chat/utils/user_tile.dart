import 'package:flutter/material.dart';
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
                height: 80,
                width: 220,
                direction: PopoverDirection.bottom,
                context: context,
                bodyBuilder: (context) => Column(
                  children: [
                    GestureDetector(
                      onTap: onAddFriend,
                      child: Container(
                        color: Colors.blue.shade200,
                        height: 40,
                        width: double.infinity,
                        child: Row(
                          spacing: 6,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 6),
                            Icon(Icons.person_sharp),
                            Text("Ajoutez en amis"),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onBlockUser,
                      child: Container(
                        color: Colors.red.shade400,
                        height: 40,
                        width: double.infinity,
                        child: Row(
                          spacing: 6,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 6),
                            Icon(Icons.block),
                            Text("Bloquez cet utilisateur"),
                          ],
                        ),
                      ),
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
