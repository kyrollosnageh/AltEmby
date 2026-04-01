import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class TvFocusCard extends StatefulWidget {
  final MediaItem item;
  final String baseUrl;
  final VoidCallback onSelect;
  final double width;
  final bool autofocus;

  const TvFocusCard({
    super.key,
    required this.item,
    required this.baseUrl,
    required this.onSelect,
    this.width = 180,
    this.autofocus = false,
  });

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _focused ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: _focused
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                : null,
            boxShadow: _focused
                ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 16)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      EmbyImage(
                        imageUrl: ImageUtils.thumbnailUrl(
                          baseUrl: widget.baseUrl,
                          itemId: widget.item.id,
                          tag: widget.item.primaryImageTag,
                        ),
                      ),
                      if (widget.item.hasProgress)
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: LinearProgressIndicator(
                            value: widget.item.progressPercent,
                            minHeight: 4,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: _focused ? 16 : 14, fontWeight: _focused ? FontWeight.bold : FontWeight.normal)),
              if (widget.item.productionYear != null)
                Text('${widget.item.productionYear}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
