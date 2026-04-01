import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

/// YouTube-style "Stats for nerds" overlay showing playback diagnostics.
class StatsOverlay extends StatefulWidget {
  final Player player;

  const StatsOverlay({super.key, required this.player});

  @override
  State<StatsOverlay> createState() => _StatsOverlayState();
}

class _StatsOverlayState extends State<StatsOverlay> {
  Timer? _refreshTimer;
  _Stats _stats = const _Stats();

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    _update();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final p = widget.player;
    final state = p.state;
    final track = state.track;

    setState(() {
      _stats = _Stats(
        mediaUri: state.playlist.medias.isNotEmpty
            ? _sanitizeUrl(state.playlist.medias[state.playlist.index].uri)
            : null,
        position: state.position,
        duration: state.duration,
        buffering: state.buffering,
        width: state.width,
        height: state.height,
        audioTrack: track.audio,
        subtitleTrack: track.subtitle,
        bitrate: state.audioBitrate,
        volume: state.volume,
        rate: state.rate,
      );
    });
  }

  /// Remove api_key from the URL for display
  String _sanitizeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final params = Map<String, String>.from(uri.queryParameters)..remove('api_key');
    return uri.replace(queryParameters: params.isEmpty ? null : params).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 48,
      left: 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
              height: 1.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Stats for nerds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                if (_stats.mediaUri != null) _row('URL', _stats.mediaUri!),
                if (_stats.width != null && _stats.height != null)
                  _row('Resolution', '${_stats.width} x ${_stats.height}'),
                _row('Position', '${_formatDuration(_stats.position)} / ${_formatDuration(_stats.duration)}'),
                _row('Buffering', _stats.buffering ? 'Yes' : 'No'),
                if (_stats.bitrate != null) _row('Audio Bitrate', '${(_stats.bitrate! / 1000).toStringAsFixed(0)} kbps'),
                _row('Playback Rate', '${_stats.rate}x'),
                _row('Volume', '${_stats.volume.toStringAsFixed(0)}%'),
                if (_stats.audioTrack != null)
                  _row('Audio Track', _trackLabel(_stats.audioTrack!)),
                if (_stats.subtitleTrack != null)
                  _row('Subtitle', _subtitleLabel(_stats.subtitleTrack!)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Text('$label: $value', overflow: TextOverflow.ellipsis, maxLines: 2);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _trackLabel(AudioTrack t) {
    final parts = <String>[];
    if (t.title != null && t.title!.isNotEmpty) parts.add(t.title!);
    if (t.language != null && t.language!.isNotEmpty) parts.add(t.language!);
    return parts.isEmpty ? 'Track ${t.id}' : parts.join(' - ');
  }

  String _subtitleLabel(SubtitleTrack t) {
    if (t == SubtitleTrack.no()) return 'Off';
    final parts = <String>[];
    if (t.title != null && t.title!.isNotEmpty) parts.add(t.title!);
    if (t.language != null && t.language!.isNotEmpty) parts.add(t.language!);
    return parts.isEmpty ? 'Track ${t.id}' : parts.join(' - ');
  }
}

class _Stats {
  final String? mediaUri;
  final Duration position;
  final Duration duration;
  final bool buffering;
  final int? width;
  final int? height;
  final AudioTrack? audioTrack;
  final SubtitleTrack? subtitleTrack;
  final double? bitrate;
  final double volume;
  final double rate;

  const _Stats({
    this.mediaUri,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffering = false,
    this.width,
    this.height,
    this.audioTrack,
    this.subtitleTrack,
    this.bitrate,
    this.volume = 100,
    this.rate = 1.0,
  });
}
