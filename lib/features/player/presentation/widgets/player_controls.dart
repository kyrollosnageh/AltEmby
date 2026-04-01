import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/player/presentation/providers/player_providers.dart';
import 'package:altemby/features/player/presentation/widgets/player_seek_bar.dart';
import 'package:altemby/features/player/presentation/widgets/track_selector_sheet.dart';

class PlayerControls extends ConsumerStatefulWidget {
  final String title;
  final VoidCallback? onStatsToggle;
  const PlayerControls({super.key, required this.title, this.onStatsToggle});

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
                child: Text('Playback Speed',
                    style: TextStyle(fontSize: 18))),
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
                  // Top bar
                  Row(children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop()),
                    Expanded(
                        child: Text(widget.title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  const Spacer(),
                  // Center controls
                  if (state.isBuffering)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              iconSize: 36,
                              icon: const Icon(Icons.replay_10,
                                  color: Colors.white),
                              onPressed: () {
                                notifier.seekRelative(
                                    const Duration(seconds: -10));
                                _startHideTimer();
                              }),
                          const SizedBox(width: 24),
                          IconButton(
                              iconSize: 56,
                              icon: Icon(
                                  state.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white),
                              onPressed: () {
                                notifier.playOrPause();
                                _startHideTimer();
                              }),
                          const SizedBox(width: 24),
                          IconButton(
                              iconSize: 36,
                              icon: const Icon(Icons.forward_30,
                                  color: Colors.white),
                              onPressed: () {
                                notifier.seekRelative(
                                    const Duration(seconds: 30));
                                _startHideTimer();
                              }),
                        ]),
                  const Spacer(),
                  // Seek bar
                  PlayerSeekBar(
                      position: state.position,
                      duration: state.duration,
                      positionText: state.positionText,
                      durationText: state.durationText,
                      onSeek: (pos) {
                        notifier.seek(pos);
                        _startHideTimer();
                      }),
                  // Bottom controls
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                            onPressed: _showSpeedSelector,
                            child: Text('${state.playbackSpeed}x',
                                style: const TextStyle(
                                    color: Colors.white))),
                        IconButton(
                            icon: const Icon(Icons.audiotrack,
                                color: Colors.white),
                            tooltip: 'Audio',
                            onPressed: () =>
                                TrackSelectorSheet.showAudioTracks(context,
                                    tracks: state.audioTracks,
                                    current: state.currentAudioTrack,
                                    onSelected: (t) =>
                                        notifier.setAudioTrack(t))),
                        IconButton(
                            icon: const Icon(Icons.subtitles,
                                color: Colors.white),
                            tooltip: 'Subtitles',
                            onPressed: () =>
                                TrackSelectorSheet.showSubtitleTracks(
                                    context,
                                    tracks: state.subtitleTracks,
                                    current: state.currentSubtitleTrack,
                                    onSelected: (t) =>
                                        notifier.setSubtitleTrack(t))),
                        if (widget.onStatsToggle != null)
                          IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white),
                              tooltip: 'Stats for nerds',
                              onPressed: widget.onStatsToggle),
                      ]),
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
