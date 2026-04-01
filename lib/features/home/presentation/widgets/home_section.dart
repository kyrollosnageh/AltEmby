import 'package:flutter/material.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_row.dart';

class HomeSection extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final String baseUrl;
  final void Function(MediaItem item) onItemTap;

  const HomeSection({super.key, required this.title, required this.items, required this.baseUrl, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        MediaRow(items: items, baseUrl: baseUrl, onItemTap: onItemTap),
      ],
    );
  }
}
