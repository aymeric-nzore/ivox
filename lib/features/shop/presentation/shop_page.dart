import 'package:flutter/material.dart';
import 'package:ivox/features/shop/services/shop_services.dart';
import 'package:ivox/features/shop/services/song_player_service.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ShopServices _shopServices = ShopServices();
  final SongPlayerService _songPlayerService = SongPlayerService();
  late Future<Map<String, List<Map<String, dynamic>>>> _shopFuture;
  final Set<String> _ownedSongIds = <String>{};
  final Set<String> _buyingItemIds = <String>{};
  String? _playingSongId;

  @override
  void initState() {
    super.initState();
    _shopFuture = _shopServices.getShopData();
    _loadOwnedItems();
  }

  Future<void> _reloadShop() async {
    setState(() {
      _shopFuture = _shopServices.getShopData();
    });
    await Future.wait([
      _shopFuture,
      _loadOwnedItems(),
    ]);
  }

  Future<void> _loadOwnedItems() async {
    final ownedItems = await _shopServices.getOwnedItems();
    final ownedSongs = ownedItems
        .where((item) => (item["type"] ?? "") == "song")
        .map((item) => (item["itemId"] ?? "").toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (!mounted) return;
    setState(() {
      _ownedSongIds
        ..clear()
        ..addAll(ownedSongs);
    });
  }

  Future<void> _buyItem(String type, Map<String, dynamic> item) async {
    final itemId = (item["_id"] ?? "").toString();
    if (itemId.isEmpty || _buyingItemIds.contains(itemId)) return;

    setState(() {
      _buyingItemIds.add(itemId);
    });

    try {
      await _shopServices.buyItem(itemId: itemId, type: type);

      if (type == "song") {
        _ownedSongIds.add(itemId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Achat reussi")),
      );

      await _reloadShop();
    } catch (error) {
      final message = error.toString();
      final alreadyBought = message.toLowerCase().contains("deja") ||
          message.toLowerCase().contains("déjà");

      if (alreadyBought && type == "song") {
        setState(() {
          _ownedSongIds.add(itemId);
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _buyingItemIds.remove(itemId);
        });
      }
    }
  }

  Future<void> _toggleSongPlayback({
    required String itemId,
    required String assetUrl,
  }) async {
    if (assetUrl.isEmpty) return;

    try {
      final isPlaying = await _songPlayerService.togglePlayback(assetUrl);
      if (!mounted) return;
      setState(() {
        _playingSongId = isPlaying ? itemId : null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lire ce son")),
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "song":
        return Icons.music_note_rounded;
      case "animation":
        return Icons.auto_awesome_motion_rounded;
      case "avatar":
        return Icons.face_retouching_natural_rounded;
      default:
        return Icons.widgets_rounded;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case "song":
        return "Songs";
      case "animation":
        return "Animations";
      case "avatar":
        return "Avatars";
      default:
        return "Items";
    }
  }

  Widget _buildSection(
    BuildContext context,
    String type,
    List<Map<String, dynamic>> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _iconForType(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _labelForType(type),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: items.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text("Aucun item pour le moment"),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = (item["title"] ?? "Item").toString();
                    final price = _toInt(item["price"]);
                    final description = (item["description"] ?? "").toString();
                    final duration = _toInt(item["duration"]);
                    final category = (item["categorie"] ?? "").toString();
                    final imageUrl = (item["assetUrl"] ?? "").toString();
                    final itemId = (item["_id"] ?? "").toString();
                    final buyCount = _toInt(item["buyCount"]);
                    final isSong = type == "song";
                    final isOwnedSong = isSong && _ownedSongIds.contains(itemId);
                    final isBuying = _buyingItemIds.contains(itemId);
                    final isPlaying = _playingSongId == itemId;

                    return Container(
                      width: 230,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          icon,
                                          size: 32,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      icon,
                                      size: 32,
                                      color: colorScheme.primary,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (duration > 0)
                            Text(
                              "Duree: ${duration}s",
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (category.isNotEmpty)
                            Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "$price",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.shopping_bag_outlined, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                "$buyCount",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: isOwnedSong
                                ? OutlinedButton.icon(
                                    onPressed: () => _toggleSongPlayback(
                                      itemId: itemId,
                                      assetUrl: imageUrl,
                                    ),
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                    ),
                                    label: Text(isPlaying ? "Pause" : "Jouer"),
                                  )
                                : ElevatedButton(
                                    onPressed: isBuying
                                        ? null
                                        : () => _buyItem(type, item),
                                    child: Text(isBuying ? "Achat..." : "Acheter"),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _songPlayerService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Boutique"), centerTitle: true),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _shopFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement de la boutique"));
          }

          final data = snapshot.data ?? const <String, List<Map<String, dynamic>>>{};

          return RefreshIndicator(
            onRefresh: _reloadShop,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildSection(context, "song", data["song"] ?? const []),
                const SizedBox(height: 18),
                _buildSection(context, "animation", data["animation"] ?? const []),
                const SizedBox(height: 18),
                _buildSection(context, "avatar", data["avatar"] ?? const []),
              ],
            ),
          );
        },
      ),
    );
  }
}
