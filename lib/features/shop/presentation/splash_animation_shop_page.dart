import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/animation_service.dart' as anim;
import '../../../core/services/api_service.dart';

class SplashAnimationShopPage extends StatefulWidget {
  const SplashAnimationShopPage({Key? key}) : super(key: key);

  @override
  State<SplashAnimationShopPage> createState() =>
      _SplashAnimationShopPageState();
}

class _SplashAnimationShopPageState extends State<SplashAnimationShopPage> {
  late anim.AnimationService _animationService;
  List<anim.Animation> _allAnimations = [];
  List<anim.Animation> _ownedAnimations = [];
  anim.Animation? _activeAnimation;
  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    final apiService = ApiService();
    _animationService = anim.AnimationService(apiService: apiService);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final animations = await _animationService.getSplashAnimations();
      final owned = await _animationService.getOwnedAnimations();
      final active = await _animationService.getActiveSplashAnimation();

      setState(() {
        _allAnimations = animations;
        _ownedAnimations = owned;
        _activeAnimation = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _buyAnimation(anim.Animation animation) async {
    try {
      final message = await _animationService.buyAnimation(animation.id);
      if (!mounted) return;
      setState(() {
        _successMessage = message;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(seconds: 1));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _successMessage = null;
      });
    }
  }

  Future<void> _equipAnimation(anim.Animation animation) async {
    try {
      final message = await _animationService.equipAnimation(animation.id);
      if (!mounted) return;
      setState(() {
        _successMessage = message;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(seconds: 1));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _successMessage = null;
      });
    }
  }

  Future<void> _unequipAnimation() async {
    try {
      final message = await _animationService.unequipAnimation();
      if (!mounted) return;
      setState(() {
        _successMessage = message;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(seconds: 1));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Animations Splash')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animations Splash'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Messages
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),

              // Animation équipée actuelle
              if (_activeAnimation != null) ...[
                Text(
                  'Animation Équipée',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: Lottie.network(
                          _activeAnimation!.assetUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.animation,
                                size: 48,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeAnimation!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _unequipAnimation,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Déséquiper (Défaut)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Animations possédées
              if (_ownedAnimations.isNotEmpty) ...[
                Text(
                  'Vos Animations (${_ownedAnimations.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _ownedAnimations.length,
                  itemBuilder: (context, index) {
                    final animation = _ownedAnimations[index];
                    final isActive =
                        _activeAnimation?.id == animation.id;

                    return GestureDetector(
                      onTap: () => _equipAnimation(animation),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Colors.green
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Lottie.network(
                                animation.assetUrl,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return Icon(
                                    Icons.animation,
                                    size: 32,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey[400],
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.all(8.0),
                              child: Text(
                                animation.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Équipée',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],

              // Animations disponibles à l'achat
              Text(
                'Boutique Animations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _allAnimations.length,
                itemBuilder: (context, index) {
                  final animation = _allAnimations[index];
                  final isOwned = _ownedAnimations
                      .any((a) => a.id == animation.id);

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Lottie.network(
                            animation.assetUrl,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Icon(
                                Icons.animation,
                                size: 32,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey[400],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                animation.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${animation.price} 💰',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.amber
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: isOwned
                                    ? null
                                    : () =>
                                        _buyAnimation(animation),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isOwned
                                          ? Colors.grey
                                          : Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                ),
                                child: Text(
                                  isOwned
                                      ? 'Possédée'
                                      : 'Acheter',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
