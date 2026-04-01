// lib/shared/widgets/media_card.dart

import 'package:flutter/material.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final String baseUrl;
  final VoidCallback onTap;
  final double width;

  const MediaCard({super.key, required this.item, required this.baseUrl, required this.onTap, this.width = 140});

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUtils.thumbnailUrl(baseUrl: baseUrl, itemId: item.id, tag: item.primaryImageTag);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: Theme.of(context).colorScheme.primary.withAlpha(30),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(fit: StackFit.expand, children: [
                  EmbyImage(imageUrl: imageUrl),
                  if (item.hasProgress)
                    Positioned(left: 0, right: 0, bottom: 0,
                      child: LinearProgressIndicator(value: item.progressPercent, minHeight: 3, backgroundColor: Colors.black54)),
                  if (item.played)
                    Positioned(top: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle, size: 16, color: Colors.green))),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            if (item.productionYear != null)
              Text('${item.productionYear}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
