import 'package:flutter/material.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_card.dart';
import 'package:altemby/shared/widgets/shimmer_grid.dart';

class MediaGrid extends StatefulWidget {
  final List<MediaItem> items;
  final String baseUrl;
  final void Function(MediaItem item) onItemTap;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const MediaGrid({super.key, required this.items, required this.baseUrl, required this.onItemTap,
    this.isLoading = false, this.hasMore = false, this.onLoadMore});

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 6;
    if (width > 600) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.isLoading) return const ShimmerGrid();
    if (widget.items.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32),
        child: Text('No items found', style: TextStyle(color: Colors.grey))));
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount(context), childAspectRatio: 0.55, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) return const Center(child: CircularProgressIndicator());
        final item = widget.items[index];
        return MediaCard(item: item, baseUrl: widget.baseUrl, onTap: () => widget.onItemTap(item));
      },
    );
  }
}
