import 'package:flutter/foundation.dart';

enum WalkthroughPage { lessons, leaderboard, chat, profile }

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

  static final AppWalkthroughController instance =
      AppWalkthroughController._();

  final List<WalkthroughStep> _steps = const [
    WalkthroughStep(
      page: WalkthroughPage.lessons,
      targetId: 'lessons_search',
      title: 'Recherche de cours',
      description: 'Trouve rapidement tes cours avec cette barre.',
      mascotAsset: 'assets/mascotte/im1.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.lessons,
      targetId: 'lessons_quiz',
      title: 'Quiz interactifs',
      description: 'Lance un quiz et gagne de XP.',
      mascotAsset: 'assets/mascotte/im2.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.leaderboard,
      targetId: 'leaderboard_top',
      title: 'Top joueur',
      description: 'Voici le joueur en tete du classement.',
      mascotAsset: 'assets/mascotte/im3.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.leaderboard,
      targetId: 'leaderboard_list',
      title: 'Classement global',
      description: 'Compare ton niveau et ton XP avec la communaute.',
      mascotAsset: 'assets/mascotte/im1.png',
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
      title: 'Demarrer une conversation',
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
      title: 'Confidentialite',
      description: 'Controle qui peut voir ton profil.',
      mascotAsset: 'assets/mascotte/im2.png',
    ),
    WalkthroughStep(
      page: WalkthroughPage.profile,
      targetId: 'profile_shop',
      title: 'Boutique',
      description: 'Accede a la boutique pour personnaliser ton experience.',
      mascotAsset: 'assets/mascotte/im3.png',
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

  static int tabIndexFromPage(WalkthroughPage page) {
    switch (page) {
      case WalkthroughPage.lessons:
        return 0;
      case WalkthroughPage.leaderboard:
        return 1;
      case WalkthroughPage.chat:
        return 2;
      case WalkthroughPage.profile:
        return 3;
    }
  }
}
