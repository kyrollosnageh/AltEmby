import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/details/presentation/providers/details_providers.dart';
import 'package:altemby/features/home/presentation/widgets/home_section.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class MovieDetailScreen extends ConsumerWidget {
  final String itemId;
  const MovieDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Error: $e'), const SizedBox(height: 16),
          FilledButton(onPressed: () => ref.invalidate(itemDetailProvider(itemId)), child: const Text('Retry'))])),
        data: (item) => _buildContent(context, ref, item, baseUrl),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, MediaItem item, String baseUrl) {
    final similarAsync = ref.watch(similarItemsProvider(itemId));
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 300, pinned: true,
        flexibleSpace: FlexibleSpaceBar(
          background: item.backdropImageTags.isNotEmpty
              ? Stack(fit: StackFit.expand, children: [
                  EmbyImage(imageUrl: ImageUtils.backdropUrl(baseUrl: baseUrl, itemId: item.id, tag: item.backdropImageTags.first)),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87])))])
              : Container(color: Colors.grey[900]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          Wrap(spacing: 12, children: [
            if (item.productionYear != null) Text('${item.productionYear}', style: const TextStyle(color: Colors.grey)),
            if (item.runtimeFormatted.isNotEmpty) Text(item.runtimeFormatted, style: const TextStyle(color: Colors.grey)),
            if (item.officialRating != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Text(item.officialRating!, style: const TextStyle(color: Colors.grey, fontSize: 12))),
            if (item.communityRating != null) Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.amber, size: 16), const SizedBox(width: 4),
              Text(item.communityRating!.toStringAsFixed(1), style: const TextStyle(color: Colors.grey))]),
          ]),
          const SizedBox(height: 16),
          if (item.genres.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 4, children: item.genres.map((g) =>
              Chip(label: Text(g, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact)).toList()),
            const SizedBox(height: 16),
          ],
          if (item.overview != null && item.overview!.isNotEmpty)
            Text(item.overview!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[300], height: 1.5)),
          const SizedBox(height: 24),
          similarAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (similar) => HomeSection(title: 'Similar', items: similar, baseUrl: baseUrl,
              onItemTap: (item) => context.push('/details/${item.id}')),
          ),
        ]))),
    ]);
  }
}
