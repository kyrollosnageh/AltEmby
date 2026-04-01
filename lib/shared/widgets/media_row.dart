import 'package:flutter/material.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_card.dart';

class MediaRow extends StatelessWidget {
  final List<MediaItem> items;
  final String baseUrl;
  final void Function(MediaItem item) onItemTap;
  final double cardWidth;
  final double height;

  const MediaRow({super.key, required this.items, required this.baseUrl, required this.onItemTap, this.cardWidth = 140, this.height = 260});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return MediaCard(item: item, baseUrl: baseUrl, width: cardWidth, onTap: () => onItemTap(item));
        },
      ),
    );
  }
}
