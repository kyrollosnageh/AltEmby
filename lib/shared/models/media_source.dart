// lib/shared/models/media_source.dart

/// Represents a media version/source from Emby (e.g., 1080p H.264, 4K HEVC).
class MediaSource {
  final String id;
  final String? name;
  final String? container;
  final int? bitrate;
  final int? size;
  final List<MediaStream> mediaStreams;

  const MediaSource({
    required this.id,
    this.name,
    this.container,
    this.bitrate,
    this.size,
    this.mediaStreams = const [],
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    final streams = (json['MediaStreams'] as List<dynamic>?)
            ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return MediaSource(
      id: json['Id'] as String,
      name: json['Name'] as String?,
      container: json['Container'] as String?,
      bitrate: json['Bitrate'] as int?,
      size: json['Size'] as int?,
      mediaStreams: streams,
    );
  }

  List<MediaStream> get videoStreams =>
      mediaStreams.where((s) => s.type == StreamType.video).toList();

  List<MediaStream> get audioStreams =>
      mediaStreams.where((s) => s.type == StreamType.audio).toList();

  List<MediaStream> get subtitleStreams =>
      mediaStreams.where((s) => s.type == StreamType.subtitle).toList();

  /// Human-readable label like "1080p H.264 · MKV · 8.2 GB"
  String get displayTitle {
    final parts = <String>[];
    final video = videoStreams.firstOrNull;
    if (video != null) {
      if (video.height != null) parts.add(video.resolutionLabel);
      if (video.codec != null) parts.add(video.codec!.toUpperCase());
    }
    if (container != null) parts.add(container!.toUpperCase());
    if (size != null) parts.add(_formatSize(size!));
    return parts.isEmpty ? name ?? id : parts.join(' \u00b7 ');
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

enum StreamType { video, audio, subtitle, unknown }

/// Represents an individual stream (video, audio, or subtitle track) within a media source.
class MediaStream {
  final int index;
  final StreamType type;
  final String? codec;
  final String? language;
  final String? title;
  final String? displayTitle;
  final int? bitRate;
  final int? channels;
  final int? width;
  final int? height;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;

  const MediaStream({
    required this.index,
    required this.type,
    this.codec,
    this.language,
    this.title,
    this.displayTitle,
    this.bitRate,
    this.channels,
    this.width,
    this.height,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      index: json['Index'] as int? ?? 0,
      type: _parseType(json['Type'] as String?),
      codec: json['Codec'] as String?,
      language: json['Language'] as String?,
      title: json['Title'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      bitRate: json['BitRate'] as int?,
      channels: json['Channels'] as int?,
      width: json['Width'] as int?,
      height: json['Height'] as int?,
      isDefault: json['IsDefault'] as bool? ?? false,
      isForced: json['IsForced'] as bool? ?? false,
      isExternal: json['IsExternal'] as bool? ?? false,
    );
  }

  static StreamType _parseType(String? type) {
    return switch (type) {
      'Video' => StreamType.video,
      'Audio' => StreamType.audio,
      'Subtitle' => StreamType.subtitle,
      _ => StreamType.unknown,
    };
  }

  /// Human-readable label for audio like "English · AAC 5.1"
  String get audioLabel {
    final parts = <String>[];
    if (displayTitle != null && displayTitle!.isNotEmpty) return displayTitle!;
    if (language != null && language!.isNotEmpty) parts.add(language!);
    if (title != null && title!.isNotEmpty) parts.add(title!);
    if (codec != null) parts.add(codec!.toUpperCase());
    if (channels != null) parts.add(_channelLayout);
    if (isDefault) parts.add('Default');
    return parts.isEmpty ? 'Track ${index + 1}' : parts.join(' \u00b7 ');
  }

  /// Human-readable label for subtitles like "English (SRT) [Default]"
  String get subtitleLabel {
    if (displayTitle != null && displayTitle!.isNotEmpty) return displayTitle!;
    final parts = <String>[];
    if (language != null && language!.isNotEmpty) parts.add(language!);
    if (title != null && title!.isNotEmpty) parts.add(title!);
    if (codec != null) parts.add(codec!.toUpperCase());
    if (isForced) parts.add('Forced');
    if (isDefault) parts.add('Default');
    if (isExternal) parts.add('External');
    return parts.isEmpty ? 'Track ${index + 1}' : parts.join(' \u00b7 ');
  }

  String get resolutionLabel {
    if (height == null) return '';
    if (height! >= 2160) return '4K';
    if (height! >= 1440) return '1440p';
    if (height! >= 1080) return '1080p';
    if (height! >= 720) return '720p';
    if (height! >= 480) return '480p';
    return '${height}p';
  }

  String get _channelLayout {
    return switch (channels) {
      1 => 'Mono',
      2 => 'Stereo',
      6 => '5.1',
      8 => '7.1',
      _ => '${channels}ch',
    };
  }
}
