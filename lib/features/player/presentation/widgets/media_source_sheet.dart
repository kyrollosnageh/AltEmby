import 'package:flutter/material.dart';
import 'package:altemby/shared/models/media_source.dart';

/// Selection state returned from the media source picker.
class MediaSourceSelection {
  final MediaSource source;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;

  const MediaSourceSelection({
    required this.source,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
  });
}

/// Bottom sheet that lets the user pick a media version, audio track,
/// and subtitle track from the available Emby media sources.
class MediaSourceSheet extends StatefulWidget {
  final List<MediaSource> sources;
  final String? currentSourceId;
  final int? currentAudioIndex;
  final int? currentSubtitleIndex;

  const MediaSourceSheet({
    super.key,
    required this.sources,
    this.currentSourceId,
    this.currentAudioIndex,
    this.currentSubtitleIndex,
  });

  /// Show the sheet and return the user's selection, or null if dismissed.
  static Future<MediaSourceSelection?> show(
    BuildContext context, {
    required List<MediaSource> sources,
    String? currentSourceId,
    int? currentAudioIndex,
    int? currentSubtitleIndex,
  }) {
    return showModalBottomSheet<MediaSourceSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MediaSourceSheet(
        sources: sources,
        currentSourceId: currentSourceId,
        currentAudioIndex: currentAudioIndex,
        currentSubtitleIndex: currentSubtitleIndex,
      ),
    );
  }

  @override
  State<MediaSourceSheet> createState() => _MediaSourceSheetState();
}

class _MediaSourceSheetState extends State<MediaSourceSheet> {
  late MediaSource _selectedSource;
  int? _selectedAudioIndex;
  int? _selectedSubtitleIndex;

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.sources.firstWhere(
      (s) => s.id == widget.currentSourceId,
      orElse: () => widget.sources.first,
    );
    _selectedAudioIndex = widget.currentAudioIndex ??
        _selectedSource.audioStreams.where((s) => s.isDefault).firstOrNull?.index;
    _selectedSubtitleIndex = widget.currentSubtitleIndex;
  }

  void _onSourceChanged(MediaSource source) {
    setState(() {
      _selectedSource = source;
      // Reset to default tracks for the new source
      _selectedAudioIndex =
          source.audioStreams.where((s) => s.isDefault).firstOrNull?.index ??
              source.audioStreams.firstOrNull?.index;
      _selectedSubtitleIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioStreams = _selectedSource.audioStreams;
    final subtitleStreams = _selectedSource.subtitleStreams;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Version section
                  if (widget.sources.length > 1) ...[
                    Text('Version', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...widget.sources.map((source) => _TrackTile(
                      label: source.displayTitle,
                      isSelected: source.id == _selectedSource.id,
                      onTap: () => _onSourceChanged(source),
                    )),
                    const Divider(height: 32),
                  ],

                  // Audio section
                  if (audioStreams.isNotEmpty) ...[
                    Text('Audio', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...audioStreams.map((stream) => _TrackTile(
                      label: stream.audioLabel,
                      isSelected: stream.index == _selectedAudioIndex,
                      onTap: () => setState(() => _selectedAudioIndex = stream.index),
                    )),
                    const Divider(height: 32),
                  ],

                  // Subtitle section
                  if (subtitleStreams.isNotEmpty) ...[
                    Text('Subtitles', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _TrackTile(
                      label: 'Off',
                      isSelected: _selectedSubtitleIndex == null,
                      onTap: () => setState(() => _selectedSubtitleIndex = null),
                    ),
                    ...subtitleStreams.map((stream) => _TrackTile(
                      label: stream.subtitleLabel,
                      isSelected: stream.index == _selectedSubtitleIndex,
                      onTap: () => setState(() => _selectedSubtitleIndex = stream.index),
                    )),
                  ],

                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      MediaSourceSelection(
                        source: _selectedSource,
                        audioStreamIndex: _selectedAudioIndex,
                        subtitleStreamIndex: _selectedSubtitleIndex,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Play'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrackTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: isSelected,
    );
  }
}
