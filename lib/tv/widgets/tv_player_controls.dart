import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/player/presentation/providers/player_providers.dart';
import 'package:altemby/features/player/presentation/widgets/player_seek_bar.dart';

class TvPlayerControls extends ConsumerStatefulWidget {
  final String title;
  const TvPlayerControls({super.key, required this.title});

  @override
  ConsumerState<TvPlayerControls> createState() => _TvPlayerControlsState();
}

class _TvPlayerControlsState extends ConsumerState<TvPlayerControls> {
  bool _visible = true;

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final notifier = ref.read(playerNotifierProvider.notifier);
    setState(() => _visible = true);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.select || LogicalKeyboardKey.enter:
        notifier.playOrPause();
      case LogicalKeyboardKey.arrowLeft:
        notifier.seekRelative(const Duration(seconds: -10));
      case LogicalKeyboardKey.arrowRight:
        notifier.seekRelative(const Duration(seconds: 30));
      case LogicalKeyboardKey.goBack || LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerNotifierProvider);

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKey,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black38,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 24)),
                ),
                const Spacer(),
                if (state.isBuffering)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Icon(state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white, size: 72),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: PlayerSeekBar(
                    position: state.position,
                    duration: state.duration,
                    positionText: state.positionText,
                    durationText: state.durationText,
                    onSeek: (pos) => ref.read(playerNotifierProvider.notifier).seek(pos),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
