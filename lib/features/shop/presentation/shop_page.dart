import 'package:flutter/material.dart';
import 'package:ivox/core/services/api_service.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/shop/services/animation_service.dart'
    as anim_service;
import 'package:ivox/features/shop/services/shop_services.dart';
import 'package:ivox/features/shop/services/song_player_service.dart';
import 'package:ivox/shared/walkthrough/app_walkthrough_controller.dart';
import 'package:ivox/shared/walkthrough/mascot_walkthrough_overlay.dart';
import 'package:lottie/lottie.dart';
import 'music_shop_page.dart';
import 'splash_animation_shop_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AuthService _authService = AuthService();
  final ShopServices _shopServices = ShopServices();
  final anim_service.AnimationService _animationService =
      anim_service.AnimationService(apiService: ApiService());
  final SongPlayerService _songPlayerService = SongPlayerService();
  late Future<Map<String, List<Map<String, dynamic>>>> _shopFuture;
  final Set<String> _ownedSongIds = <String>{};
  final Set<String> _ownedAnimationIds = <String>{};
  final Set<String> _buyingItemIds = <String>{};
  final Set<String> _equippingAnimationIds = <String>{};
  final GlobalKey _introCardKey = GlobalKey();
  final GlobalKey _coinsKey = GlobalKey();
  final GlobalKey _songsSectionKey = GlobalKey();
  final GlobalKey _animationsSectionKey = GlobalKey();
  final GlobalKey _avatarsSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  String? _activeAnimationId;

  @override
  void initState() {
    super.initState();
    _shopFuture = _shopServices.getShopData();
    _loadOwnedItems();
    _loadActiveAnimation();
    AppWalkthroughController.instance.addListener(_onWalkthroughChanged);
  }

  void _onWalkthroughChanged() {
    final walkthrough = AppWalkthroughController.instance;
    final step = walkthrough.currentStep;
    if (!mounted || step == null || step.page != WalkthroughPage.shop) {
      return;
    }

    GlobalKey? targetKey;
    switch (step.targetId) {
      case 'shop_intro':
        targetKey = _introCardKey;
        break;
      case 'shop_coins':
        targetKey = _coinsKey;
        break;
      case 'shop_songs':
        targetKey = _songsSectionKey;
        break;
      case 'shop_animations':
        targetKey = _animationsSectionKey;
        break;
      case 'shop_avatars':
        targetKey = _avatarsSectionKey;
        break;
    }

    if (targetKey == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = targetKey!.currentContext;
      if (targetContext == null || !mounted) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        alignment: 0.2,
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _reloadShop() async {
    setState(() {
      _shopFuture = _shopServices.getShopData();
    });
    await Future.wait([
      _shopFuture,
      _loadOwnedItems(),
      _loadActiveAnimation(),
      _authService.refreshProfile(),
    ]);
  }

  Future<void> _loadOwnedItems() async {
    final ownedItems = await _shopServices.getOwnedItems();
    final ownedSongs = ownedItems
        .where((item) => (item["type"] ?? "") == "song")
        .map((item) => (item["itemId"] ?? "").toString())
        .where((id) => id.isNotEmpty)
        .toSet();
    final ownedAnimations = ownedItems
        .where((item) => (item["type"] ?? "") == "animation")
        .map((item) => (item["itemId"] ?? "").toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (!mounted) return;
    setState(() {
      _ownedSongIds
        ..clear()
        ..addAll(ownedSongs);
      _ownedAnimationIds
        ..clear()
        ..addAll(ownedAnimations);
    });
  }

  Future<void> _loadActiveAnimation() async {
    try {
      final active = await _animationService.getActiveSplashAnimation();
      if (!mounted) return;
      setState(() {
        _activeAnimationId = active?.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeAnimationId = null;
      });
    }
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
      } else if (type == "animation") {
        _ownedAnimationIds.add(itemId);
      }

      final currentBuyCount = _toInt(item["buyCount"]);
      item["buyCount"] = currentBuyCount + 1;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Achat reussi")));
      await _authService.refreshProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      final message = error.toString();
      final alreadyBought =
          message.toLowerCase().contains("deja") ||
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
    required String title,
    required String assetUrl,
  }) async {
    if (assetUrl.isEmpty) return;

    try {
      await _songPlayerService.playOrToggle(
        itemId: itemId,
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
            "Impossible de lire ce son: ${error.toString().replaceFirst('Exception: ', '')}",
          ),
        ),
      );
    }
  }

  Future<void> _toggleAnimationEquip({
    required String animationId,
    required bool isCurrentlyActive,
  }) async {
    if (_equippingAnimationIds.contains(animationId)) return;

    setState(() {
      _equippingAnimationIds.add(animationId);
    });

    try {
      final message = isCurrentlyActive
          ? await _animationService.unequipAnimation()
          : await _animationService.equipAnimation(animationId);

      if (!mounted) return;
      setState(() {
        _activeAnimationId = isCurrentlyActive ? null : animationId;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _authService.refreshProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _equippingAnimationIds.remove(animationId);
        });
      }
    }
  }

  Future<void> _showAnimationPreview({
    required String title,
    required String assetUrl,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: assetUrl.isEmpty
                      ? const Icon(
                          Icons.animation,
                          size: 88,
                          color: Colors.white54,
                        )
                      : Lottie.network(
                          assetUrl,
                          fit: BoxFit.contain,
                          frameRate: FrameRate.composition,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.animation,
                            size: 88,
                            color: Colors.white54,
                          ),
                        ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  bool _isLikelyImageUrl(String url) {
    if (url.isEmpty) {
      return false;
    }

    final normalized = url.toLowerCase();
    if (normalized.contains('/video/upload/') ||
        normalized.contains('/raw/upload/')) {
      return false;
    }

    if (normalized.contains('/image/upload/')) {
      return true;
    }

    return RegExp(
      r'\.(png|jpe?g|webp|gif|bmp|heic|heif)(\?|$)',
    ).hasMatch(normalized);
  }

  Widget _buildSection(
    BuildContext context,
    String type,
    List<Map<String, dynamic>> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _iconForType(type);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 360
        ? 190.0
        : screenWidth < 500
        ? 220.0
        : 250.0;
    final sectionHeight = screenWidth < 360 ? 300.0 : 320.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _labelForType(type),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              "${items.length} items",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: sectionHeight,
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = (item["title"] ?? "Item").toString();
                    final price = _toInt(item["price"]);
                    final description = (item["description"] ?? "").toString();
                    final duration = _toInt(item["duration"]);
                    final category = (item["categorie"] ?? "").toString();
                    final imageUrl = (item["assetUrl"] ?? "").toString();
                    final canRenderImage = _isLikelyImageUrl(imageUrl);
                    final isAnimation = type == "animation";
                    final itemId = (item["_id"] ?? "").toString();
                    final buyCount = _toInt(item["buyCount"]);
                    final isSong = type == "song";
                    final isOwnedSong =
                        isSong && _ownedSongIds.contains(itemId);
                    final isOwnedAnimation =
                        isAnimation && _ownedAnimationIds.contains(itemId);
                    final isAnimationActive =
                        isAnimation && _activeAnimationId == itemId;
                    final isBuying = _buyingItemIds.contains(itemId);
                    final isEquipping =
                        isAnimation && _equippingAnimationIds.contains(itemId);
                    final isSmallCard = cardWidth < 210;
                    final isPlaying =
                        _songPlayerService.currentItemId == itemId &&
                        _songPlayerService.isPlaying;

                    return Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 118,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: canRenderImage
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                      bottom: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Icon(
                                                  icon,
                                                  size: 34,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                    ),
                                  )
                                : isAnimation
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                      bottom: Radius.circular(12),
                                    ),
                                    child: Lottie.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      repeat: false,
                                      frameRate: FrameRate.composition,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Icon(
                                                  icon,
                                                  size: 34,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      icon,
                                      size: 34,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if (duration > 0) "${duration}s",
                                      if (category.isNotEmpty) category,
                                    ].join(" • "),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7CC),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.monetization_on_rounded,
                                              size: 14,
                                              color: Color(0xFFA46A00),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "$price",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFA46A00),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 15,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$buyCount",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: isOwnedSong
                                        ? OutlinedButton.icon(
                                            onPressed: () =>
                                                _toggleSongPlayback(
                                                  itemId: itemId,
                                                  title: title,
                                                  assetUrl: imageUrl,
                                                ),
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons
                                                        .pause_circle_filled_rounded
                                                  : Icons
                                                        .play_circle_fill_rounded,
                                            ),
                                            label: Text(
                                              isPlaying ? "Pause" : "Jouer",
                                            ),
                                          )
                                        : isAnimation
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              SizedBox(
                                                height: 34,
                                                child: OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _showAnimationPreview(
                                                        title: title,
                                                        assetUrl: imageUrl,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.fullscreen_rounded,
                                                    size: 14,
                                                  ),
                                                  label: Text(
                                                    isSmallCard
                                                        ? "Preview"
                                                        : "Aperçu",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              SizedBox(
                                                height: 34,
                                                child: isOwnedAnimation
                                                    ? ElevatedButton.icon(
                                                        onPressed: isEquipping
                                                            ? null
                                                            : () => _toggleAnimationEquip(
                                                                animationId:
                                                                    itemId,
                                                                isCurrentlyActive:
                                                                    isAnimationActive,
                                                              ),
                                                        icon: Icon(
                                                          isAnimationActive
                                                              ? Icons
                                                                    .link_off_rounded
                                                              : Icons
                                                                    .check_circle_rounded,
                                                          size: 14,
                                                        ),
                                                        label: Text(
                                                          isEquipping
                                                              ? "..."
                                                              : (isAnimationActive
                                                                    ? "Déséquiper"
                                                                    : "Équiper"),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                        ),
                                                      )
                                                    : ElevatedButton.icon(
                                                        onPressed: isBuying
                                                            ? null
                                                            : () => _buyItem(
                                                                type,
                                                                item,
                                                              ),
                                                        icon: const Icon(
                                                          Icons
                                                              .shopping_cart_checkout_rounded,
                                                          size: 14,
                                                        ),
                                                        label: Text(
                                                          isBuying
                                                              ? "Achat..."
                                                              : "Acheter",
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          )
                                        : ElevatedButton(
                                            onPressed: isBuying
                                                ? null
                                                : () => _buyItem(type, item),
                                            child: Text(
                                              isBuying ? "Achat..." : "Acheter",
                                            ),
                                          ),
                                  ),
                                ],
                              ),
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
    AppWalkthroughController.instance.removeListener(_onWalkthroughChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Boutique"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music_rounded),
            tooltip: 'Boutique Musiques',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MusicShopPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_motion_rounded),
            tooltip: 'Animations Splash',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SplashAnimationShopPage(),
                ),
              );
            },
          ),
          StreamBuilder(
            stream: _authService.userDocStream(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final coins = _toInt(data?["coins"]);

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  key: _coinsKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7CC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE7D179)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 16,
                        color: Color(0xFFA46A00),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$coins",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA46A00),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _shopFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text("Erreur de chargement de la boutique"),
                );
              }

              final data =
                  snapshot.data ?? const <String, List<Map<String, dynamic>>>{};

              return RefreshIndicator(
                onRefresh: _reloadShop,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    Container(
                      key: _introCardKey,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Decouvre les meilleurs items et achete en un clic.",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      key: _songsSectionKey,
                      child: _buildSection(
                        context,
                        "song",
                        data["song"] ?? const [],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      key: _animationsSectionKey,
                      child: _buildSection(
                        context,
                        "animation",
                        data["animation"] ?? const [],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      key: _avatarsSectionKey,
                      child: _buildSection(
                        context,
                        "avatar",
                        data["avatar"] ?? const [],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          MascotWalkthroughOverlay(
            page: WalkthroughPage.shop,
            targets: {
              'shop_intro': _introCardKey,
              'shop_coins': _coinsKey,
              'shop_songs': _songsSectionKey,
              'shop_animations': _animationsSectionKey,
              'shop_avatars': _avatarsSectionKey,
            },
            onTabSelected: (_) {},
          ),
        ],
      ),
    );
  }
}
