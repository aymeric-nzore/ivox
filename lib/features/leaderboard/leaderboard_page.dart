import 'package:flutter/material.dart';
import 'package:ivox/features/leaderboard/services/leaderboard_service.dart';
import 'package:ivox/shared/walkthrough/app_walkthrough_controller.dart';
import 'package:ivox/shared/walkthrough/mascot_walkthrough_overlay.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';

class LeaderboardPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const LeaderboardPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final GlobalKey _topPlayerKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();

  List<Map<String, dynamic>> _sortUsers(List<Map<String, dynamic>> users) {
    final sorted = List<Map<String, dynamic>>.from(users);
    sorted.sort((a, b) {
      final levelA = _toInt(a['level']);
      final levelB = _toInt(b['level']);
      if (levelA != levelB) {
        return levelB.compareTo(levelA);
      }

      final xpA = _toInt(a['xp']);
      final xpB = _toInt(b['xp']);
      return xpB.compareTo(xpA);
    });
    return sorted;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Color _podiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return Colors.transparent;
    }
  }

  Widget _buildUserTile(
    BuildContext context,
    Map<String, dynamic> user,
    int rank,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final username = (user['username'] ?? user['email'] ?? 'Utilisateur').toString();
    final photoUrl = user['photoUrl']?.toString();
    final level = _toInt(user['level']);
    final xp = _toInt(user['xp']);
    final coins = _toInt(user['coins']);
    final isTopThree = rank <= 3;
    final frameColor = _podiumColor(rank);

    return Container(
      key: rank == 1 ? _topPlayerKey : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isTopThree
            ? frameColor.withValues(alpha: 0.18)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTopThree ? frameColor : colorScheme.outline.withValues(alpha: 0.2),
          width: isTopThree ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTopThree ? frameColor : colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundImage:
                photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl == null || photoUrl.isEmpty
              ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Lv $level', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('XP $xp', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Color(0xFF6D4C41),
                ),
              ),
              Text(
                "$coins",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        centerTitle: true,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: () {
              AppWalkthroughController.instance.start();
              widget.onTabSelected(0);
            },
            icon: const Icon(Icons.help_outline),
            tooltip: 'Tutoriel',
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _leaderboardService.getUserStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Erreur lors du chargement du classement'),
                );
              }

              final users = snapshot.data ?? <Map<String, dynamic>>[];
              if (users.isEmpty) {
                return const Center(
                  child: Text('Aucun utilisateur dans le classement'),
                );
              }

              final sorted = _sortUsers(users);

              return ListView.builder(
                key: _listKey,
                padding: const EdgeInsets.only(top: 10, bottom: 14),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  return _buildUserTile(context, sorted[index], index + 1);
                },
              );
            },
          ),
          MascotWalkthroughOverlay(
            page: WalkthroughPage.leaderboard,
            targets: {
              'leaderboard_top': _topPlayerKey,
              'leaderboard_list': _listKey,
            },
            onTabSelected: widget.onTabSelected,
          ),
        ],
      ),
    );
  }
}
