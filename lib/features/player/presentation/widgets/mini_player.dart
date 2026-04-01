// lib/features/player/presentation/widgets/mini_player.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/player/presentation/providers/audio_providers.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(audioPlayerStateProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state.currentItem == null) return const SizedBox.shrink();
        final item = state.currentItem!;

        return GestureDetector(
          onTap: () => context.push('/audio-player'),
          child: Container(
            height: 64,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                // Album art
                SizedBox(
                  width: 64,
                  height: 64,
                  child: EmbyImage(
                    imageUrl: ImageUtils.thumbnailUrl(
                      baseUrl: baseUrl,
                      itemId: item.id,
                      tag: item.primaryImageTag,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + artist
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (item.seriesName != null)
                        Text(
                          item.seriesName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                // Controls
                IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => ref.read(audioPlayerServiceProvider).playOrPause(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: state.hasNext
                      ? () => ref.read(audioPlayerServiceProvider).next()
                      : null,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
