// lib/features/player/presentation/providers/player_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/player/data/playback_reporter.dart';

final playbackReporterProvider = Provider<PlaybackReporter>(
  (ref) => PlaybackReporter(apiClient: ref.watch(embyApiClientProvider)),
);

class PlayerState {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final double playbackSpeed;
  final String? currentItemId;
  final List<AudioTrack> audioTracks;
  final List<SubtitleTrack> subtitleTracks;
  final AudioTrack? currentAudioTrack;
  final SubtitleTrack? currentSubtitleTrack;

  const PlayerState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.playbackSpeed = 1.0,
    this.currentItemId,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.currentAudioTrack,
    this.currentSubtitleTrack,
  });

  PlayerState copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    double? playbackSpeed,
    String? currentItemId,
    List<AudioTrack>? audioTracks,
    List<SubtitleTrack>? subtitleTracks,
    AudioTrack? currentAudioTrack,
    SubtitleTrack? currentSubtitleTrack,
  }) {
    return PlayerState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      currentItemId: currentItemId ?? this.currentItemId,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
      currentSubtitleTrack: currentSubtitleTrack ?? this.currentSubtitleTrack,
    );
  }

  String get positionText => _formatDuration(position);
  String get durationText => _formatDuration(duration);

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Player player = Player();
  late final VideoController videoController;
  final PlaybackReporter _reporter;
  final String _baseUrl;
  final String? _token;
  DateTime _lastProgressReport = DateTime.now();
  final List<StreamSubscription> _subscriptions = [];

  PlayerNotifier({
    required PlaybackReporter reporter,
    required String baseUrl,
    String? token,
  })  : _reporter = reporter,
        _baseUrl = baseUrl,
        _token = token,
        super(const PlayerState()) {
    videoController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    _subscriptions.add(player.stream.position.listen((pos) {
      state = state.copyWith(position: pos);
      _maybeReportProgress(pos);
    }));
    _subscriptions.add(player.stream.duration.listen((dur) {
      state = state.copyWith(duration: dur);
    }));
    _subscriptions.add(player.stream.playing.listen((p) {
      state = state.copyWith(isPlaying: p);
    }));
    _subscriptions.add(player.stream.buffering.listen((b) {
      state = state.copyWith(isBuffering: b);
    }));
    _subscriptions.add(player.stream.completed.listen((c) {
      if (c) state = state.copyWith(isCompleted: true);
    }));
    _subscriptions.add(player.stream.tracks.listen((tracks) {
      state = state.copyWith(
        audioTracks: tracks.audio,
        subtitleTracks: tracks.subtitle,
      );
    }));
    _subscriptions.add(player.stream.track.listen((track) {
      state = state.copyWith(
        currentAudioTrack: track.audio,
        currentSubtitleTrack: track.subtitle,
      );
    }));
  }

  Future<void> openItem({
    required String itemId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int resumePositionTicks = 0,
  }) async {
    state = state.copyWith(currentItemId: itemId);

    final path = ApiEndpoints.videoStream(itemId);
    final params = <String, dynamic>{
      'Static': 'true',
      if (_token != null) 'api_key': _token,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex.toString(),
      if (subtitleStreamIndex != null) 'SubtitleStreamIndex': subtitleStreamIndex.toString(),
    };
    final query = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    final url = '$_baseUrl$path?$query';

    await player.open(Media(url), play: true);

    if (resumePositionTicks > 0) {
      await player.seek(PlaybackReporter.ticksToDuration(resumePositionTicks));
    }

    await _reporter.reportPlaybackStart(
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      positionTicks: resumePositionTicks,
    );
  }

  void _maybeReportProgress(Duration position) {
    if (state.currentItemId == null) return;
    final now = DateTime.now();
    if (now.difference(_lastProgressReport).inSeconds >= 10) {
      _lastProgressReport = now;
      _reporter.reportPlaybackProgress(
        itemId: state.currentItemId!,
        positionTicks: PlaybackReporter.durationToTicks(position),
        isPaused: !state.isPlaying,
      );
    }
  }

  Future<void> playOrPause() => player.playOrPause();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> setRate(double rate) async {
    await player.setRate(rate);
    state = state.copyWith(playbackSpeed: rate);
  }
  Future<void> setAudioTrack(AudioTrack track) => player.setAudioTrack(track);
  Future<void> setSubtitleTrack(SubtitleTrack track) =>
      player.setSubtitleTrack(track);

  Future<void> seekRelative(Duration offset) async {
    final newPos = state.position + offset;
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > state.duration ? state.duration : newPos);
    await player.seek(clamped);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    if (state.currentItemId != null) {
      _reporter.reportPlaybackStopped(
        itemId: state.currentItemId!,
        positionTicks: PlaybackReporter.durationToTicks(state.position),
      );
    }
    player.dispose();
    super.dispose();
  }
}

final playerNotifierProvider =
    StateNotifierProvider.autoDispose<PlayerNotifier, PlayerState>((ref) {
  final reporter = ref.watch(playbackReporterProvider);
  final apiClient = ref.watch(embyApiClientProvider);
  return PlayerNotifier(
    reporter: reporter,
    baseUrl: apiClient.baseUrl,
    token: apiClient.authInterceptor.token,
  );
});
