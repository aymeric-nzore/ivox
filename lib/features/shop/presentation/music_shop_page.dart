import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/shop/services/shop_services.dart';
import 'package:ivox/features/shop/services/song_player_service.dart';

class MusicShopPage extends StatefulWidget {
  const MusicShopPage({super.key});

  @override
  State<MusicShopPage> createState() => _MusicShopPageState();
}

class _MusicShopPageState extends State<MusicShopPage> {
  final ShopServices _shopServices = ShopServices();
  final AuthService _authService = AuthService();
  final SongPlayerService _songPlayerService = SongPlayerService();

  List<Map<String, dynamic>> _songs = const [];
  final Set<String> _ownedSongIds = <String>{};
  final Set<String> _buyingItemIds = <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _shopServices.getShopData();
      final ownedItems = await _shopServices.getOwnedItems();

      final ownedSongs = ownedItems
          .where((item) => (item['type'] ?? '').toString() == 'song')
          .map((item) => (item['itemId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      if (!mounted) return;
      setState(() {
        _songs = data['song'] ?? const [];
        _ownedSongIds
          ..clear()
          ..addAll(ownedSongs);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _buySong(Map<String, dynamic> song) async {
    final songId = (song['_id'] ?? '').toString();
    if (songId.isEmpty || _buyingItemIds.contains(songId)) return;

    setState(() {
      _buyingItemIds.add(songId);
    });

    try {
      await _shopServices.buyItem(itemId: songId, type: 'song');
      if (!mounted) return;
      setState(() {
        _ownedSongIds.add(songId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musique achetee avec succes')),
      );
      await _authService.refreshProfile();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _buyingItemIds.remove(songId);
        });
      }
    }
  }

  Future<void> _toggleSongPlayback(Map<String, dynamic> song) async {
    final songId = (song['_id'] ?? '').toString();
    final title = (song['title'] ?? 'Music').toString();
    final assetUrl = (song['assetUrl'] ?? '').toString();

    if (songId.isEmpty || assetUrl.isEmpty) return;

    try {
      await _songPlayerService.playOrToggle(
        itemId: songId,
        title: title,
        url: assetUrl,
      );
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de lire ce son: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Widget _buildCurrentPlaybackCard(ColorScheme colorScheme) {
    final currentTitle = _songPlayerService.currentTitle;
    final hasCurrent = currentTitle != null && currentTitle.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lecteur musique',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCurrent ? currentTitle : 'Aucune musique en lecture',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: hasCurrent
                ? () async {
                    await _songPlayerService.toggleCurrentPlayback();
                    if (mounted) {
                      setState(() {});
                    }
                  }
                : null,
            icon: Icon(
              _songPlayerService.isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(
    BuildContext context,
    Map<String, dynamic> song, {
    required bool ownedOnly,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final songId = (song['_id'] ?? '').toString();
    final title = (song['title'] ?? 'Music').toString();
    final description = (song['description'] ?? '').toString();
    final category = (song['categorie'] ?? '').toString();
    final duration = _toInt(song['duration']);
    final price = _toInt(song['price']);
    final buyCount = _toInt(song['buyCount']);

    final isOwned = _ownedSongIds.contains(songId);
    final isBuying = _buyingItemIds.contains(songId);
    final isPlaying =
        _songPlayerService.currentItemId == songId && _songPlayerService.isPlaying;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$price coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA46A00),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  [
                    if (duration > 0) '${duration}s',
                    if (category.isNotEmpty) category,
                  ].join(' • '),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(Icons.shopping_bag_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '$buyCount',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: isOwned
                  ? OutlinedButton.icon(
                      onPressed: () => _toggleSongPlayback(song),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                      ),
                      label: Text(isPlaying ? 'Pause' : 'Jouer'),
                    )
                  : ownedOnly
                      ? const SizedBox.shrink()
                      : ElevatedButton.icon(
                          onPressed: isBuying ? null : () => _buySong(song),
                          icon: const Icon(Icons.shopping_cart_checkout_rounded),
                          label: Text(isBuying ? 'Achat...' : 'Acheter'),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Boutique Musiques'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final ownedSongs = _songs
        .where((song) => _ownedSongIds.contains((song['_id'] ?? '').toString()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique Musiques'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            _buildCurrentPlaybackCard(colorScheme),
            const SizedBox(height: 16),
            Text(
              'Vos musiques (${ownedSongs.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (ownedSongs.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Vous ne possedez pas encore de musique.'),
              )
            else
              ...ownedSongs.map(
                (song) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSongCard(context, song, ownedOnly: true),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Boutique musiques',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (_songs.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Aucune musique disponible pour le moment.'),
              )
            else
              ..._songs.map(
                (song) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSongCard(context, song, ownedOnly: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
