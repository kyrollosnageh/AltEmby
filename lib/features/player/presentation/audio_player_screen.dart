// lib/features/player/presentation/audio_player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/player/data/audio_player_service.dart' as audio_svc;
import 'package:altemby/features/player/presentation/providers/audio_providers.dart';
import 'package:altemby/features/player/presentation/widgets/player_seek_bar.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(audioPlayerStateProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;
    final service = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Now Playing'),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final item = state.currentItem;
          if (item == null) {
            return const Center(child: Text('No track playing'));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: EmbyImage(
                      imageUrl: ImageUtils.posterUrl(
                        baseUrl: baseUrl,
                        itemId: item.id,
                        tag: item.primaryImageTag,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Track info
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (item.seriesName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.seriesName!,
                      style: TextStyle(color: Colors.grey[400]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 24),
                // Seek bar
                PlayerSeekBar(
                  position: state.position,
                  duration: state.duration,
                  positionText: state.positionText,
                  durationText: state.durationText,
                  onSeek: (pos) => service.seek(pos),
                ),
                const SizedBox(height: 16),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: state.shuffleEnabled ? Theme.of(context).colorScheme.primary : null,
                      ),
                      onPressed: () => service.toggleShuffle(),
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: state.hasPrevious ? () => service.previous() : null,
                    ),
                    IconButton(
                      iconSize: 56,
                      icon: Icon(
                        state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      ),
                      onPressed: () => service.playOrPause(),
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next),
                      onPressed: state.hasNext ? () => service.next() : null,
                    ),
                    IconButton(
                      icon: Icon(
                        state.repeatMode == audio_svc.RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                        color: state.repeatMode != audio_svc.RepeatMode.off
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => service.toggleRepeat(),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
