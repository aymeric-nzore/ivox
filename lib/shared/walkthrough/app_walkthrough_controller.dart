import 'package:flutter/foundation.dart';

enum WalkthroughPage { lessons, leaderboard, chat, profile, shop }

class WalkthroughStep {
  final WalkthroughPage page;
  final String targetId;
  final String title;
  final String description;
  final String mascotAsset;

  const WalkthroughStep({
    required this.page,
    required this.targetId,
    required this.title,
    required this.description,
    required this.mascotAsset,
  });
}

class AppWalkthroughController extends ChangeNotifier {
  AppWalkthroughController._();

  static final AppWalkthroughController instance = AppWalkthroughController._();

  final List<WalkthroughStep> _steps = const [
    WalkthroughStep(
      page: WalkthroughPage.lessons,
      targetId: 'lessons_search',
      title: 'Bonjour, je suis Mylann',
      description:
          'Je vais te montrer les parties importantes de l\'application.',
      mascotAsset: 'assets/mascotte/im6.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.lessons,
      targetId: 'lessons_quiz',
      title: 'Quiz interactifs',
      description: 'Lance un quiz et gagne de l\'XP.',
      mascotAsset: 'assets/mascotte/im2.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.leaderboard,
      targetId: 'leaderboard_top',
      title: 'Top joueur',
      description: 'Voici le joueur en tête du classement.',
      mascotAsset: 'assets/mascotte/im5.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.leaderboard,
      targetId: 'leaderboard_list',
      title: 'Classement global',
      description: 'Compare ton niveau et ton XP avec la communauté.',
      mascotAsset: 'assets/mascotte/im4.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.chat,
      targetId: 'chat_list',
      title: 'Liste des contacts',
      description: 'Tous les utilisateurs disponibles se trouvent ici.',
      mascotAsset: 'assets/mascotte/im2.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.chat,
      targetId: 'chat_first_user',
      title: 'Démarrer une conversation',
      description: 'Touchez un utilisateur pour ouvrir le chat.',
      mascotAsset: 'assets/mascotte/im3.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.profile,
      targetId: 'profile_username',
      title: 'Nom utilisateur',
      description: 'Modifie ton nom visible sur ton profil.',
      mascotAsset: 'assets/mascotte/im1.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.profile,
      targetId: 'profile_privacy',
      title: 'Confidentialité',
      description: 'Contrôle qui peut voir ton profil.',
      mascotAsset: 'assets/mascotte/im4.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.profile,
      targetId: 'profile_dictionary',
      title: 'Dictionnaire',
      description: 'Utilise le dictionnaire pour retrouver rapidement un mot.',
      mascotAsset: 'assets/mascotte/im4.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.profile,
      targetId: 'profile_shop',
      title: 'Boutique',
      description: 'Accède à la boutique pour personnaliser ton expérience.',
      mascotAsset: 'assets/mascotte/im6.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.shop,
      targetId: 'shop_intro',
      title: 'Bienvenue dans la boutique',
      description: 'Ici, tu peux acheter des musiques, animations et avatars.',
      mascotAsset: 'assets/mascotte/im5.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.shop,
      targetId: 'shop_songs',
      title: 'Rayon musiques',
      description:
          'Commence par cette section pour acheter puis jouer tes sons.',
      mascotAsset: 'assets/mascotte/im5.png',
    ),
  ];

  bool _isActive = false;
  int _index = 0;

  bool get isActive => _isActive;
  int get index => _index;

  WalkthroughStep? get currentStep {
    if (!_isActive) return null;
    if (_index < 0 || _index >= _steps.length) return null;
    return _steps[_index];
  }

  WalkthroughStep? get nextStep {
    if (!_isActive) return null;
    final nextIndex = _index + 1;
    if (nextIndex >= _steps.length) return null;
    return _steps[nextIndex];
  }

  void start() {
    _isActive = true;
    _index = 0;
    notifyListeners();
  }

  void stop() {
    _isActive = false;
    notifyListeners();
  }

  void next() {
    if (!_isActive) return;

    if (_index < _steps.length - 1) {
      _index += 1;
    } else {
      _isActive = false;
    }
    notifyListeners();
  }

  static bool isBottomTabPage(WalkthroughPage page) {
    return page != WalkthroughPage.shop;
  }

  static int tabIndexFromPage(WalkthroughPage page) {
    switch (page) {
      case WalkthroughPage.lessons:
        return 0;
      case WalkthroughPage.leaderboard:
        return 1;
      case WalkthroughPage.chat:
        return 3;
      case WalkthroughPage.profile:
        return 4;
      case WalkthroughPage.shop:
        return 4;
    }
  }
}
