import 'package:flutter/foundation.dart';
import 'package:ivox/core/services/audio_background_state.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class SongPlayerService {
  static final SongPlayerService _instance = SongPlayerService._internal();
  SongPlayerService._internal();
  factory SongPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  String? _currentSourceKey;
  String? _currentItemId;
  String? _currentTitle;
  final ValueNotifier<int> revisionNotifier = ValueNotifier<int>(0);

  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  String? get currentItemId => _currentItemId;
  String? get currentTitle => _currentTitle;
  bool get isPlaying => _player.playing;

  void _notify() {
    revisionNotifier.value = revisionNotifier.value + 1;
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    return trimmed;
  }

  String _toCloudinaryMp3Url(String url) {
    if (!url.contains('res.cloudinary.com')) {
      return url;
    }
    if (url.contains('/upload/f_mp3/')) {
      return url;
    }
    return url.replaceFirst('/upload/', '/upload/f_mp3/');
  }

  String _toCloudinaryAudioFallbackUrl(String url) {
    if (!url.contains('res.cloudinary.com')) {
      return url;
    }
    return url.replaceFirst('/upload/', '/upload/f_mp3,ac_none/');
  }

  Future<void> _setSource(String sourceUrl, MediaItem mediaItem) async {
    if (AudioBackgroundState.isInitialized) {
      try {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(sourceUrl),
            tag: mediaItem,
          ),
        );
        return;
      } catch (_) {
        // Fall back to plain URL mode if media handler is not ready.
      }
    }

    await _player.setUrl(sourceUrl);
  }

  Future<void> _setSourceWithFallback({
    required String url,
    required String itemId,
    required String title,
  }) async {
    final normalized = _normalizeUrl(url);
    final encodedNormalized = Uri.encodeFull(normalized);

    final mediaItem = MediaItem(
      id: itemId,
      title: title,
      album: 'Ivox Shop',
      artist: 'Ivox',
    );

    try {
      await _setSource(encodedNormalized, mediaItem);
      return;
    } catch (_) {}

    final fallbackMp3 = Uri.encodeFull(_toCloudinaryMp3Url(normalized));
    if (fallbackMp3 != encodedNormalized) {
      try {
        await _setSource(fallbackMp3, mediaItem);
        return;
      } catch (_) {}
    }

    final fallbackAudio = Uri.encodeFull(_toCloudinaryAudioFallbackUrl(normalized));
    if (fallbackAudio != encodedNormalized) {
      await _setSource(fallbackAudio, mediaItem);
      return;
    }

    throw Exception('Source audio invalide');
  }

  Future<bool> playOrToggle({
    required String itemId,
    required String title,
    required String url,
  }) async {
    if (_currentItemId == itemId && _player.playing) {
      await _player.pause();
      _notify();
      return false;
    }

    if (_currentItemId != itemId || _currentSourceKey != url) {
      await _setSourceWithFallback(
        url: url,
        itemId: itemId,
        title: title,
      );
      _currentSourceKey = url;
      _currentItemId = itemId;
      _currentTitle = title;
      await _player.setLoopMode(LoopMode.one);
    }

    await _player.play();
    _notify();
    return true;
  }

  Future<void> toggleCurrentPlayback() async {
    if (_currentItemId == null) return;

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    _notify();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
    _notify();
  }

  Future<void> seekForward10() async {
    final duration = _player.duration ?? Duration.zero;
    final current = _player.position;
    final target = current + const Duration(seconds: 10);
    await _player.seek(target > duration ? duration : target);
  }

  Future<void> seekBackward10() async {
    final current = _player.position;
    final target = current - const Duration(seconds: 10);
    await _player.seek(target.isNegative ? Duration.zero : target);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSourceKey = null;
    _currentItemId = null;
    _currentTitle = null;
    _notify();
  }
}
