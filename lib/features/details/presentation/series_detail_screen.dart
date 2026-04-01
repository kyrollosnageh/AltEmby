import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/details/presentation/providers/details_providers.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const SeriesDetailScreen({super.key, required this.itemId});
  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  String? _selectedSeasonId;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemDetailProvider(widget.itemId));
    final seasonsAsync = ref.watch(seasonsProvider(widget.itemId));
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (item) => _buildContent(context, item, seasonsAsync, baseUrl),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MediaItem item, AsyncValue<List<MediaItem>> seasonsAsync, String baseUrl) {
    return CustomScrollView(slivers: [
      SliverAppBar(expandedHeight: 250, pinned: true,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(item.name, style: const TextStyle(fontSize: 16)),
          background: item.backdropImageTags.isNotEmpty
              ? Stack(fit: StackFit.expand, children: [
                  EmbyImage(imageUrl: ImageUtils.backdropUrl(baseUrl: baseUrl, itemId: item.id, tag: item.backdropImageTags.first)),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87])))])
              : Container(color: Colors.grey[900]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 12, children: [
            if (item.productionYear != null) Text('${item.productionYear}', style: const TextStyle(color: Colors.grey)),
            if (item.officialRating != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Text(item.officialRating!, style: const TextStyle(color: Colors.grey, fontSize: 12))),
            if (item.communityRating != null) Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.amber, size: 16), const SizedBox(width: 4),
              Text(item.communityRating!.toStringAsFixed(1), style: const TextStyle(color: Colors.grey))]),
          ]),
          if (item.overview != null) ...[const SizedBox(height: 12),
            Text(item.overview!, style: TextStyle(color: Colors.grey[300], height: 1.5))],
          const SizedBox(height: 16),
        ]))),
      SliverToBoxAdapter(child: seasonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error loading seasons: $e'),
        data: (seasons) {
          if (seasons.isEmpty) return const SizedBox.shrink();
          _selectedSeasonId ??= seasons.first.id;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: seasons.map((season) {
                final isSelected = season.id == _selectedSeasonId;
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(season.name), selected: isSelected,
                    onSelected: (_) => setState(() => _selectedSeasonId = season.id)));
              }).toList())),
            const SizedBox(height: 8),
          ]);
        })),
      if (_selectedSeasonId != null)
        _EpisodesList(seriesId: widget.itemId, seasonId: _selectedSeasonId!, baseUrl: baseUrl),
    ]);
  }
}

class _EpisodesList extends ConsumerWidget {
  final String seriesId;
  final String seasonId;
  final String baseUrl;
  const _EpisodesList({required this.seriesId, required this.seasonId, required this.baseUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(episodesProvider((seriesId: seriesId, seasonId: seasonId)));
    return episodesAsync.when(
      loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))),
      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
      data: (episodes) => SliverList(delegate: SliverChildBuilderDelegate((context, index) {
        final ep = episodes[index];
        return ListTile(
          leading: SizedBox(width: 120, child: ClipRRect(borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              AspectRatio(aspectRatio: 16 / 9,
                child: EmbyImage(imageUrl: ImageUtils.itemImageUrl(
                  baseUrl: baseUrl, itemId: ep.id,
                  imageType: ep.primaryImageTag != null ? 'Primary' : 'Backdrop',
                  tag: ep.primaryImageTag, maxWidth: 240))),
              if (ep.hasProgress) Positioned(left: 0, right: 0, bottom: 0,
                child: LinearProgressIndicator(value: ep.progressPercent, minHeight: 3, backgroundColor: Colors.black54)),
            ]))),
          title: Text(ep.episodeNumber != null ? '${ep.episodeNumber}. ${ep.name}' : ep.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(ep.runtimeFormatted, style: const TextStyle(color: Colors.grey)),
          trailing: ep.played ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
          onTap: () => context.push(
            '/player/${ep.id}?title=${Uri.encodeComponent(ep.seriesName != null ? '${ep.seriesName} - ${ep.name}' : ep.name)}&resume=${ep.playbackPositionTicks}',
          ),
        );
      }, childCount: episodes.length)),
    );
  }
}
