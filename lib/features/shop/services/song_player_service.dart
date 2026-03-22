import 'package:just_audio/just_audio.dart';

class SongPlayerService {
  static final SongPlayerService _instance = SongPlayerService._internal();
  SongPlayerService._internal();
  factory SongPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  Future<bool> togglePlayback(String url) async {
    if (_currentUrl == url && _player.playing) {
      await _player.pause();
      return false;
    }

    if (_currentUrl != url) {
      await _player.setUrl(url);
      _currentUrl = url;
    }

    await _player.play();
    return true;
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }
}
