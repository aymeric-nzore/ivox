import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ivox/features/auth/services/auth_service.dart';

class TutorialLaunchService {
  TutorialLaunchService._();

  static final TutorialLaunchService instance = TutorialLaunchService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _keyPrefix = 'walkthrough_seen_v1_';

  String _keyForUser(String userId) => '$_keyPrefix$userId';

  Future<bool> shouldStartTutorial({required bool requestedByRoute}) async {
    await AuthService().refreshProfile();
    final userId = AuthService().getUser()?.uid;

    if (userId == null || userId.isEmpty) {
      return requestedByRoute;
    }

    final alreadySeen = await _storage.read(key: _keyForUser(userId));
    if (alreadySeen == 'true') {
      return false;
    }

    // Start for explicit first-login navigation and also for users
    // who have never seen the walkthrough on this device.
    return true;
  }

  Future<void> markTutorialSeenForCurrentUser() async {
    final userId = AuthService().getUser()?.uid;
    if (userId == null || userId.isEmpty) return;
    await _storage.write(key: _keyForUser(userId), value: 'true');
  }
}