# Phase 3 -- Video Playback: mpv Integration, Player UI, Subtitles, Watch State Sync

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full video player using media_kit (mpv/libmpv) with custom overlay controls, gesture controls, subtitle/audio track selection, and watch state sync back to the Emby server.

**Architecture:** Player feature with PlayerService managing media_kit Player lifecycle, VideoPlayerScreen with custom overlay, and PlaybackReporter for Emby session reporting. Wakelock to prevent screen sleep during playback.

**Tech Stack:** media_kit, media_kit_video, media_kit_libs_android_video, media_kit_libs_ios_video, wakelock_plus

---

## File Structure

```
lib/
├── features/
│   └── player/
│       ├── data/
│       │   └── playback_reporter.dart       # Reports play/progress/stop to Emby
│       ├── presentation/
│       │   ├── video_player_screen.dart      # Full-screen video player
│       │   ├── providers/
│       │   │   └── player_providers.dart     # Player + controller providers
│       │   └── widgets/
│       │       ├── player_controls.dart      # Custom overlay controls
│       │       ├── player_seek_bar.dart      # Seek bar with buffered indicator
│       │       └── track_selector_sheet.dart # Bottom sheet for audio/subtitle selection
```

---

### Task 1: Add media_kit Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add media_kit packages to pubspec.yaml**

Add to the `dependencies:` section:

```yaml
  media_kit: ^1.1.11
  media_kit_video: ^1.2.5
  media_kit_libs_android_video: ^1.3.6
  media_kit_libs_ios_video: ^1.1.4
  wakelock_plus: ^1.2.8
```

- [ ] **Step 2: Run pub get**

```bash
flutter pub get
```

- [ ] **Step 3: Add MediaKit.ensureInitialized() to main.dart**

In `lib/main.dart`, add import and initialization call:

Add import at top:
```dart
import 'package:media_kit/media_kit.dart';
```

Add `MediaKit.ensureInitialized();` right after `WidgetsFlutterBinding.ensureInitialized();` in the `main()` function.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore: add media_kit and wakelock_plus dependencies"
```

---

### Task 2: Playback Reporter (Watch State Sync)

**Files:**
- Create: `lib/features/player/data/playback_reporter.dart`
- Create: `test/features/player/data/playback_reporter_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/features/player/data/playback_reporter_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/player/data/playback_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

void main() {
  late MockEmbyApiClient mockClient;
  late PlaybackReporter reporter;

  setUp(() {
    mockClient = MockEmbyApiClient();
    reporter = PlaybackReporter(apiClient: mockClient);
  });

  group('reportPlaybackStart', () {
    test('sends correct payload to /Sessions/Playing', () async {
      when(() => mockClient.post(
            '/Sessions/Playing',
            data: any(named: 'data'),
          )).thenAnswer((_) async => null);

      await reporter.reportPlaybackStart(
        itemId: 'item-1',
        mediaSourceId: 'src-1',
        positionTicks: 0,
        isPaused: false,
      );

      verify(() => mockClient.post(
            '/Sessions/Playing',
            data: {
              'ItemId': 'item-1',
              'MediaSourceId': 'src-1',
              'PositionTicks': 0,
              'PlayMethod': 'DirectPlay',
              'CanSeek': true,
              'IsPaused': false,
              'IsMuted': false,
            },
          )).called(1);
    });
  });

  group('reportPlaybackProgress', () {
    test('sends correct payload to /Sessions/Playing/Progress', () async {
      when(() => mockClient.post(
            '/Sessions/Playing/Progress',
            data: any(named: 'data'),
          )).thenAnswer((_) async => null);

      await reporter.reportPlaybackProgress(
        itemId: 'item-1',
        positionTicks: 300000000000,
        isPaused: false,
      );

      verify(() => mockClient.post(
            '/Sessions/Playing/Progress',
            data: {
              'ItemId': 'item-1',
              'PositionTicks': 300000000000,
              'IsPaused': false,
              'IsMuted': false,
              'PlayMethod': 'DirectPlay',
              'CanSeek': true,
            },
          )).called(1);
    });
  });

  group('reportPlaybackStopped', () {
    test('sends correct payload to /Sessions/Playing/Stopped', () async {
      when(() => mockClient.post(
            '/Sessions/Playing/Stopped',
            data: any(named: 'data'),
          )).thenAnswer((_) async => null);

      await reporter.reportPlaybackStopped(
        itemId: 'item-1',
        positionTicks: 500000000000,
      );

      verify(() => mockClient.post(
            '/Sessions/Playing/Stopped',
            data: {
              'ItemId': 'item-1',
              'PositionTicks': 500000000000,
            },
          )).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement PlaybackReporter**

```dart
// lib/features/player/data/playback_reporter.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';

class PlaybackReporter {
  final EmbyApiClient _apiClient;

  PlaybackReporter({required EmbyApiClient apiClient})
      : _apiClient = apiClient;

  Future<void> reportPlaybackStart({
    required String itemId,
    String? mediaSourceId,
    int positionTicks = 0,
    bool isPaused = false,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.playbackStart,
        data: {
          'ItemId': itemId,
          if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
          'PositionTicks': positionTicks,
          'PlayMethod': 'DirectPlay',
          'CanSeek': true,
          'IsPaused': isPaused,
          'IsMuted': false,
        },
      );
    } catch (_) {
      // Silently fail - don't interrupt playback for reporting errors
    }
  }

  Future<void> reportPlaybackProgress({
    required String itemId,
    required int positionTicks,
    bool isPaused = false,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.playbackProgress,
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
          'IsPaused': isPaused,
          'IsMuted': false,
          'PlayMethod': 'DirectPlay',
          'CanSeek': true,
        },
      );
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> reportPlaybackStopped({
    required String itemId,
    required int positionTicks,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.playbackStopped,
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
        },
      );
    } catch (_) {
      // Silently fail
    }
  }

  /// Convert Duration to Emby ticks (10,000,000 ticks = 1 second)
  static int durationToTicks(Duration duration) {
    return duration.inMicroseconds * 10;
  }

  /// Convert Emby ticks to Duration
  static Duration ticksToDuration(int ticks) {
    return Duration(microseconds: ticks ~/ 10);
  }
}
```

- [ ] **Step 4: Run test to verify passes**
- [ ] **Step 5: Commit**

```bash
git add lib/features/player/data/ test/features/player/
git commit -m "feat: add PlaybackReporter for Emby watch state sync"
```

---

### Task 3: Player Providers

**Files:**
- Create: `lib/features/player/presentation/providers/player_providers.dart`

- [ ] **Step 1: Create player providers**

```dart
// lib/features/player/presentation/providers/player_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/player/data/playback_reporter.dart';

final playbackReporterProvider = Provider<PlaybackReporter>(
  (ref) => PlaybackReporter(apiClient: ref.watch(embyApiClientProvider)),
);

/// Manages a single Player + VideoController lifecycle.
/// Disposed when the provider is disposed (player screen pops).
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Player _player;
  final VideoController _controller;
  final PlaybackReporter _reporter;
  final String _baseUrl;
  final String? _token;
  DateTime _lastProgressReport = DateTime.now();

  Player get player => _player;
  VideoController get controller => _controller;

  PlayerNotifier({
    required PlaybackReporter reporter,
    required String baseUrl,
    String? token,
  })  : _player = Player(),
        _controller = VideoController(Player()),
        _reporter = reporter,
        _baseUrl = baseUrl,
        _token = token,
        super(const PlayerState()) {
    // Re-create controller with the actual player
    _initController();
  }

  late final VideoController videoController;

  void _initController() {
    videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    // Listen for position changes to report progress
    _player.stream.position.listen((position) {
      state = state.copyWith(position: position);
      _maybeReportProgress(position);
    });

    _player.stream.duration.listen((duration) {
      state = state.copyWith(duration: duration);
    });

    _player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player.stream.buffering.listen((buffering) {
      state = state.copyWith(isBuffering: buffering);
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        state = state.copyWith(isCompleted: true);
      }
    });

    _player.stream.tracks.listen((tracks) {
      state = state.copyWith(
        audioTracks: tracks.audio,
        subtitleTracks: tracks.subtitle,
      );
    });

    _player.stream.track.listen((track) {
      state = state.copyWith(
        currentAudioTrack: track.audio,
        currentSubtitleTrack: track.subtitle,
      );
    });
  }

  /// Open a media item for direct play.
  Future<void> openItem({
    required String itemId,
    String? mediaSourceId,
    int resumePositionTicks = 0,
  }) async {
    state = state.copyWith(currentItemId: itemId);

    // Build direct stream URL
    final path = ApiEndpoints.videoStream(itemId);
    final params = <String, dynamic>{
      'Static': 'true',
      if (_token != null) 'api_key': _token,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = '$_baseUrl$path?$query';

    await _player.open(Media(url), play: true);

    // Seek to resume position if needed
    if (resumePositionTicks > 0) {
      final resumeDuration = PlaybackReporter.ticksToDuration(resumePositionTicks);
      await _player.seek(resumeDuration);
    }

    // Report playback start
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

  Future<void> playOrPause() => _player.playOrPause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setRate(double rate) async {
    await _player.setRate(rate);
    state = state.copyWith(playbackSpeed: rate);
  }
  Future<void> setAudioTrack(AudioTrack track) => _player.setAudioTrack(track);
  Future<void> setSubtitleTrack(SubtitleTrack track) => _player.setSubtitleTrack(track);

  Future<void> seekRelative(Duration offset) async {
    final newPos = state.position + offset;
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > state.duration ? state.duration : newPos);
    await _player.seek(clamped);
  }

  @override
  void dispose() {
    // Report playback stopped
    if (state.currentItemId != null) {
      _reporter.reportPlaybackStopped(
        itemId: state.currentItemId!,
        positionTicks: PlaybackReporter.durationToTicks(state.position),
      );
    }
    _player.dispose();
    super.dispose();
  }
}

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

/// Provider that creates a fresh PlayerNotifier per usage.
/// Auto-disposed when the player screen is popped.
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/player/presentation/providers/
git commit -m "feat: add PlayerNotifier with media_kit integration and progress reporting"
```

---

### Task 4: Player Control Widgets

**Files:**
- Create: `lib/features/player/presentation/widgets/player_seek_bar.dart`
- Create: `lib/features/player/presentation/widgets/track_selector_sheet.dart`
- Create: `lib/features/player/presentation/widgets/player_controls.dart`

- [ ] **Step 1: Create PlayerSeekBar**

```dart
// lib/features/player/presentation/widgets/player_seek_bar.dart

import 'package:flutter/material.dart';

class PlayerSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final String positionText;
  final String durationText;
  final ValueChanged<Duration> onSeek;

  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.positionText,
    required this.durationText,
    required this.onSeek,
  });

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  bool _dragging = false;
  double _dragValue = 0.0;

  double get _progress {
    if (widget.duration.inMilliseconds == 0) return 0.0;
    if (_dragging) return _dragValue;
    return widget.position.inMilliseconds / widget.duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: _progress.clamp(0.0, 1.0),
            onChangeStart: (value) {
              setState(() {
                _dragging = true;
                _dragValue = value;
              });
            },
            onChanged: (value) {
              setState(() => _dragValue = value);
            },
            onChangeEnd: (value) {
              setState(() => _dragging = false);
              final seekTo = Duration(
                milliseconds: (value * widget.duration.inMilliseconds).round(),
              );
              widget.onSeek(seekTo);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.positionText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(widget.durationText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create TrackSelectorSheet**

```dart
// lib/features/player/presentation/widgets/track_selector_sheet.dart

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class TrackSelectorSheet<T> extends StatelessWidget {
  final String title;
  final List<T> tracks;
  final T? currentTrack;
  final ValueChanged<T> onSelected;
  final String Function(T track) labelBuilder;

  const TrackSelectorSheet({
    super.key,
    required this.title,
    required this.tracks,
    required this.currentTrack,
    required this.onSelected,
    required this.labelBuilder,
  });

  static void showAudioTracks(
    BuildContext context, {
    required List<AudioTrack> tracks,
    required AudioTrack? current,
    required ValueChanged<AudioTrack> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => TrackSelectorSheet<AudioTrack>(
        title: 'Audio',
        tracks: tracks,
        currentTrack: current,
        onSelected: (track) {
          onSelected(track);
          Navigator.pop(context);
        },
        labelBuilder: (t) {
          final parts = <String>[];
          if (t.title != null && t.title!.isNotEmpty) parts.add(t.title!);
          if (t.language != null && t.language!.isNotEmpty) parts.add(t.language!);
          return parts.isEmpty ? 'Track ${t.id}' : parts.join(' - ');
        },
      ),
    );
  }

  static void showSubtitleTracks(
    BuildContext context, {
    required List<SubtitleTrack> tracks,
    required SubtitleTrack? current,
    required ValueChanged<SubtitleTrack> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => TrackSelectorSheet<SubtitleTrack>(
        title: 'Subtitles',
        tracks: tracks,
        currentTrack: current,
        onSelected: (track) {
          onSelected(track);
          Navigator.pop(context);
        },
        labelBuilder: (t) {
          if (t == SubtitleTrack.no()) return 'Off';
          final parts = <String>[];
          if (t.title != null && t.title!.isNotEmpty) parts.add(t.title!);
          if (t.language != null && t.language!.isNotEmpty) parts.add(t.language!);
          return parts.isEmpty ? 'Track ${t.id}' : parts.join(' - ');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          ...tracks.map((track) {
            final isSelected = track == currentTrack;
            return ListTile(
              title: Text(labelBuilder(track)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onSelected(track),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create PlayerControls overlay**

```dart
// lib/features/player/presentation/widgets/player_controls.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/player/presentation/providers/player_providers.dart';
import 'package:altemby/features/player/presentation/widgets/player_seek_bar.dart';
import 'package:altemby/features/player/presentation/widgets/track_selector_sheet.dart';

class PlayerControls extends ConsumerStatefulWidget {
  final String title;

  const PlayerControls({super.key, required this.title});

  @override
  ConsumerState<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends ConsumerState<PlayerControls> {
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _toggleVisibility() {
    setState(() => _visible = !_visible);
    if (_visible) _startHideTimer();
  }

  void _showSpeedSelector() {
    final notifier = ref.read(playerNotifierProvider.notifier);
    final currentSpeed = ref.read(playerNotifierProvider).playbackSpeed;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Playback Speed', style: TextStyle(fontSize: 18)),
            ),
            for (final speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0])
              ListTile(
                title: Text('${speed}x'),
                trailing: speed == currentSpeed
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  notifier.setRate(speed);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerNotifierProvider);
    final notifier = ref.read(playerNotifierProvider.notifier);

    return GestureDetector(
      onTap: _toggleVisibility,
      // Vertical gestures for volume/brightness (mobile)
      onVerticalDragUpdate: (details) {
        // Left side: brightness, Right side: volume
        // Implementation deferred to Phase 7 polish
      },
      // Horizontal swipe: seek
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 0) {
          notifier.seekRelative(const Duration(seconds: 10));
        } else {
          notifier.seekRelative(const Duration(seconds: -10));
        }
        _startHideTimer();
      },
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_visible,
          child: Container(
            color: Colors.black38,
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar: title + back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Center: play/pause + buffering
                  const Spacer(),
                  if (state.isBuffering)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Skip back
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () {
                            notifier.seekRelative(const Duration(seconds: -10));
                            _startHideTimer();
                          },
                        ),
                        const SizedBox(width: 24),
                        // Play/Pause
                        IconButton(
                          iconSize: 56,
                          icon: Icon(
                            state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            notifier.playOrPause();
                            _startHideTimer();
                          },
                        ),
                        const SizedBox(width: 24),
                        // Skip forward
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.forward_30, color: Colors.white),
                          onPressed: () {
                            notifier.seekRelative(const Duration(seconds: 30));
                            _startHideTimer();
                          },
                        ),
                      ],
                    ),
                  const Spacer(),

                  // Bottom bar: seek + controls
                  PlayerSeekBar(
                    position: state.position,
                    duration: state.duration,
                    positionText: state.positionText,
                    durationText: state.durationText,
                    onSeek: (pos) {
                      notifier.seek(pos);
                      _startHideTimer();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Speed
                      TextButton(
                        onPressed: _showSpeedSelector,
                        child: Text(
                          '${state.playbackSpeed}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Audio tracks
                      IconButton(
                        icon: const Icon(Icons.audiotrack, color: Colors.white),
                        tooltip: 'Audio',
                        onPressed: () {
                          TrackSelectorSheet.showAudioTracks(
                            context,
                            tracks: state.audioTracks,
                            current: state.currentAudioTrack,
                            onSelected: (t) => notifier.setAudioTrack(t),
                          );
                        },
                      ),
                      // Subtitles
                      IconButton(
                        icon: const Icon(Icons.subtitles, color: Colors.white),
                        tooltip: 'Subtitles',
                        onPressed: () {
                          TrackSelectorSheet.showSubtitleTracks(
                            context,
                            tracks: state.subtitleTracks,
                            current: state.currentSubtitleTrack,
                            onSelected: (t) => notifier.setSubtitleTrack(t),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/player/presentation/widgets/
git commit -m "feat: add player control widgets (seek bar, track selector, overlay)"
```

---

### Task 5: Video Player Screen

**Files:**
- Create: `lib/features/player/presentation/video_player_screen.dart`
- Modify: `lib/app_router.dart` (add player route)

- [ ] **Step 1: Create VideoPlayerScreen**

```dart
// lib/features/player/presentation/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:altemby/features/player/presentation/providers/player_providers.dart';
import 'package:altemby/features/player/presentation/widgets/player_controls.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String title;
  final int resumePositionTicks;

  const VideoPlayerScreen({
    super.key,
    required this.itemId,
    required this.title,
    this.resumePositionTicks = 0,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Lock to landscape and hide system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    // Open the media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerNotifierProvider.notifier).openItem(
            itemId: widget.itemId,
            resumePositionTicks: widget.resumePositionTicks,
          );
    });
  }

  @override
  void dispose() {
    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(playerNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video surface
          Video(
            controller: notifier.videoController,
            controls: NoVideoControls,
            fit: BoxFit.contain,
            fill: Colors.black,
          ),
          // Custom controls overlay
          PlayerControls(title: widget.title),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add player route to app_router.dart**

Add import at top of `lib/app_router.dart`:
```dart
import 'package:altemby/features/player/presentation/video_player_screen.dart';
```

Add this route after the `/details/:id` route (still inside the `routes:` list):

```dart
      GoRoute(
        path: '/player/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'] ?? '';
          final resumeTicks = int.tryParse(
                state.uri.queryParameters['resume'] ?? '0') ?? 0;
          return VideoPlayerScreen(
            itemId: itemId,
            title: title,
            resumePositionTicks: resumeTicks,
          );
        },
      ),
```

- [ ] **Step 3: Add a "Play" button to MovieDetailScreen**

In `lib/features/details/presentation/movie_detail_screen.dart`, add a Play button. Add import at top:
```dart
import 'package:go_router/go_router.dart';
```

Find the metadata `Wrap` widget and add this play button right before it:

```dart
                // Play button
                FilledButton.icon(
                  onPressed: () {
                    final resume = item.playbackPositionTicks;
                    context.push(
                      '/player/${item.id}?title=${Uri.encodeComponent(item.name)}&resume=$resume',
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(item.hasProgress ? 'Resume' : 'Play'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),
```

- [ ] **Step 4: Run flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/player/presentation/video_player_screen.dart lib/app_router.dart lib/features/details/presentation/movie_detail_screen.dart
git commit -m "feat: add VideoPlayerScreen with direct play and watch state sync"
```

---

### Task 6: Final Verification

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: no issues (or only warnings about unused imports which should be fixed).

- [ ] **Step 3: Commit any fixes and tag**

```bash
git tag -a v0.3.0-phase3 -m "Phase 3 complete: Video player with mpv, controls, watch state sync"
```

---

## Summary

Phase 3 delivers:
- **6 tasks**
- **media_kit integration** with hardware-accelerated mpv playback
- **PlaybackReporter** syncing play/progress/stop to Emby (tested)
- **PlayerNotifier** managing Player lifecycle, position/duration streams, track selection
- **Custom overlay controls**: play/pause, skip 10s/30s, seek bar, speed selector
- **Audio/subtitle track selection** via bottom sheets
- **VideoPlayerScreen** with landscape lock, immersive mode, wakelock
- **Play/Resume button** on MovieDetailScreen with resume position support
- **Router integration** with `/player/:id` route
