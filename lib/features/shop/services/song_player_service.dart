import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
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
  bool _backgroundInitDone = false;
  bool _backgroundInitFailed = false;

  AudioPlayer get player => _player;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  String? get currentItemId => _currentItemId;
  String? get currentTitle => _currentTitle;
  bool get isPlaying => _player.playing;

  void _notify() {
    revisionNotifier.value = revisionNotifier.value + 1;
  }

  Future<void> _ensureBackgroundAudioInit() async {
    if (_backgroundInitDone || _backgroundInitFailed) {
      return;
    }

    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.ivox.app.audio',
        androidNotificationChannelName: 'Lecture audio Ivox',
        androidNotificationOngoing: true,
      );
      _backgroundInitDone = true;
    } catch (_) {
      _backgroundInitFailed = true;
    }
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith("//")) {
      return "https:$trimmed";
    }
    return trimmed;
  }

  String _toCloudinaryMp3Url(String url) {
    if (!url.contains("res.cloudinary.com")) {
      return url;
    }

    if (url.contains("/upload/f_mp3/")) {
      return url;
    }

    return url.replaceFirst("/upload/", "/upload/f_mp3/");
  }

  String _toCloudinaryAudioFallbackUrl(String url) {
    if (!url.contains("res.cloudinary.com")) {
      return url;
    }

    final withAudioCodec = url.replaceFirst("/upload/", "/upload/f_mp3,ac_none/");
    return withAudioCodec;
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

    Future<void> setPrimary(String sourceUrl) async {
      if (_backgroundInitDone) {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(sourceUrl),
            tag: mediaItem,
          ),
        );
      } else {
        await _player.setUrl(sourceUrl);
      }
    }

    try {
      await setPrimary(encodedNormalized);
    } catch (_) {
      final fallbackUrl = _toCloudinaryMp3Url(normalized);
      final encodedFallback = Uri.encodeFull(fallbackUrl);
      if (encodedFallback != encodedNormalized) {
        try {
          await setPrimary(encodedFallback);
          return;
        } catch (_) {}
      }

      final audioFallback = _toCloudinaryAudioFallbackUrl(normalized);
      final encodedAudioFallback = Uri.encodeFull(audioFallback);
      if (encodedAudioFallback != encodedNormalized) {
        await setPrimary(encodedAudioFallback);
        return;
      }

      rethrow;
    }
  }

  Future<bool> playOrToggle({
    required String itemId,
    required String title,
    required String url,
  }) async {
    await _ensureBackgroundAudioInit();

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
