import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class TrackSelectorSheet<T> extends StatelessWidget {
  final String title;
  final List<T> tracks;
  final T? currentTrack;
  final ValueChanged<T> onSelected;
  final String Function(T track) labelBuilder;

  const TrackSelectorSheet({
    super.key,
    required this.title,
    required this.tracks,
    required this.currentTrack,
    required this.onSelected,
    required this.labelBuilder,
  });

  static void showAudioTracks(
    BuildContext context, {
    required List<AudioTrack> tracks,
    required AudioTrack? current,
    required ValueChanged<AudioTrack> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => TrackSelectorSheet<AudioTrack>(
        title: 'Audio',
        tracks: tracks,
        currentTrack: current,
        onSelected: (t) {
          onSelected(t);
          Navigator.pop(context);
        },
        labelBuilder: (t) {
          final parts = <String>[];
          if (t.title != null && t.title!.isNotEmpty) parts.add(t.title!);
          if (t.language != null && t.language!.isNotEmpty) {
            parts.add(t.language!);
          }
          return parts.isEmpty ? 'Track ${t.id}' : parts.join(' - ');
        },
      ),
    );
  }

  static void showSubtitleTracks(
    BuildContext context, {
    required List<SubtitleTrack> tracks,
    required SubtitleTrack? current,
    required ValueChanged<SubtitleTrack> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => TrackSelectorSheet<SubtitleTrack>(
        title: 'Subtitles',
        tracks: tracks,
        currentTrack: current,
        onSelected: (t) {
          onSelected(t);
          Navigator.pop(context);
        },
        labelBuilder: (t) {
          if (t == SubtitleTrack.no()) return 'Off';
          final parts = <String>[];
          if (t.title != null && t.title!.isNotEmpty) parts.add(t.title!);
          if (t.language != null && t.language!.isNotEmpty) {
            parts.add(t.language!);
          }
          return parts.isEmpty ? 'Track ${t.id}' : parts.join(' - ');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...tracks.map((track) {
            final isSelected = track == currentTrack;
            return ListTile(
              title: Text(labelBuilder(track)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onSelected(track),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
