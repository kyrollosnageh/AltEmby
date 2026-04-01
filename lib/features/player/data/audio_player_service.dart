// lib/features/player/data/audio_player_service.dart

import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/features/player/data/playback_reporter.dart';
import 'package:altemby/shared/models/media_item.dart';

enum RepeatMode { off, one, all }

class AudioPlayerState {
  final List<MediaItem> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;

  const AudioPlayerState({
    this.queue = const [],
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.repeatMode = RepeatMode.off,
    this.shuffleEnabled = false,
  });

  MediaItem? get currentItem =>
      queue.isNotEmpty && currentIndex < queue.length ? queue[currentIndex] : null;

  bool get hasNext => currentIndex < queue.length - 1 || repeatMode == RepeatMode.all;
  bool get hasPrevious => currentIndex > 0;

  String get positionText => _fmt(position);
  String get durationText => _fmt(duration);

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  AudioPlayerState copyWith({
    List<MediaItem>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
  }) => AudioPlayerState(
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    repeatMode: repeatMode ?? this.repeatMode,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
  );

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}

class AudioPlayerService {
  final Player _player = Player();
  final PlaybackReporter _reporter;
  final String _baseUrl;
  final String? _token;
  DateTime _lastReport = DateTime.now();

  final _stateController = StreamController<AudioPlayerState>.broadcast();
  Stream<AudioPlayerState> get stateStream => _stateController.stream;
  AudioPlayerState _state = const AudioPlayerState();
  AudioPlayerState get state => _state;

  AudioPlayerService({
    required PlaybackReporter reporter,
    required String baseUrl,
    String? token,
  }) : _reporter = reporter, _baseUrl = baseUrl, _token = token {
    _player.stream.position.listen((p) => _update(position: p));
    _player.stream.duration.listen((d) => _update(duration: d));
    _player.stream.playing.listen((p) => _update(isPlaying: p));
    _player.stream.buffering.listen((b) => _update(isBuffering: b));
    _player.stream.completed.listen((c) { if (c) _onTrackCompleted(); });
  }

  void _update({Duration? position, Duration? duration, bool? isPlaying, bool? isBuffering}) {
    _state = _state.copyWith(
      position: position, duration: duration,
      isPlaying: isPlaying, isBuffering: isBuffering,
    );
    _stateController.add(_state);
    if (position != null) _maybeReport(position);
  }

  void _maybeReport(Duration pos) {
    final item = _state.currentItem;
    if (item == null) return;
    if (DateTime.now().difference(_lastReport).inSeconds >= 10) {
      _lastReport = DateTime.now();
      _reporter.reportPlaybackProgress(
        itemId: item.id,
        positionTicks: PlaybackReporter.durationToTicks(pos),
        isPaused: !_state.isPlaying,
      );
    }
  }

  String _buildUrl(String itemId) {
    final path = ApiEndpoints.audioStream(itemId);
    final params = <String, String>{
      'Static': 'true',
      if (_token != null) 'api_key': _token,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_baseUrl$path?$query';
  }

  Future<void> playItem(MediaItem item) async {
    await playQueue([item], startIndex: 0);
  }

  Future<void> playQueue(List<MediaItem> items, {int startIndex = 0}) async {
    _state = _state.copyWith(queue: items, currentIndex: startIndex);
    await _playCurrentItem();
  }

  Future<void> _playCurrentItem() async {
    final item = _state.currentItem;
    if (item == null) return;

    final url = _buildUrl(item.id);
    await _player.open(Media(url), play: true);

    _reporter.reportPlaybackStart(
      itemId: item.id,
      positionTicks: 0,
    );
    _stateController.add(_state);
  }

  void _onTrackCompleted() {
    final item = _state.currentItem;
    if (item != null) {
      _reporter.reportPlaybackStopped(
        itemId: item.id,
        positionTicks: PlaybackReporter.durationToTicks(_state.duration),
      );
    }

    if (_state.repeatMode == RepeatMode.one) {
      _playCurrentItem();
    } else if (_state.hasNext) {
      next();
    } else if (_state.repeatMode == RepeatMode.all && _state.queue.isNotEmpty) {
      _state = _state.copyWith(currentIndex: 0);
      _playCurrentItem();
    }
  }

  Future<void> playOrPause() => _player.playOrPause();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> next() async {
    if (_state.currentIndex < _state.queue.length - 1) {
      _state = _state.copyWith(currentIndex: _state.currentIndex + 1);
      await _playCurrentItem();
    }
  }

  Future<void> previous() async {
    if (_state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_state.currentIndex > 0) {
      _state = _state.copyWith(currentIndex: _state.currentIndex - 1);
      await _playCurrentItem();
    }
  }

  void toggleRepeat() {
    final next = switch (_state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    _state = _state.copyWith(repeatMode: next);
    _stateController.add(_state);
  }

  void toggleShuffle() {
    _state = _state.copyWith(shuffleEnabled: !_state.shuffleEnabled);
    if (_state.shuffleEnabled) {
      final current = _state.currentItem;
      final shuffled = List<MediaItem>.from(_state.queue)..shuffle();
      if (current != null) {
        shuffled.remove(current);
        shuffled.insert(0, current);
      }
      _state = _state.copyWith(queue: shuffled, currentIndex: 0);
    }
    _stateController.add(_state);
  }

  void dispose() {
    final item = _state.currentItem;
    if (item != null) {
      _reporter.reportPlaybackStopped(
        itemId: item.id,
        positionTicks: PlaybackReporter.durationToTicks(_state.position),
      );
    }
    _player.dispose();
    _stateController.close();
  }
}
