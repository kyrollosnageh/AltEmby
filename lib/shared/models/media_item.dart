// lib/shared/models/media_item.dart

enum MediaType {
  movie, series, season, episode, audio, musicAlbum, musicArtist,
  audioBook, boxSet, playlist, folder, unknown;

  static MediaType fromString(String? type) {
    return switch (type) {
      'Movie' => MediaType.movie,
      'Series' => MediaType.series,
      'Season' => MediaType.season,
      'Episode' => MediaType.episode,
      'Audio' => MediaType.audio,
      'MusicAlbum' => MediaType.musicAlbum,
      'MusicArtist' => MediaType.musicArtist,
      'AudioBook' => MediaType.audioBook,
      'BoxSet' => MediaType.boxSet,
      'Playlist' => MediaType.playlist,
      'Folder' || 'CollectionFolder' || 'UserView' => MediaType.folder,
      _ => MediaType.unknown,
    };
  }
}

class MediaItem {
  final String id;
  final String name;
  final MediaType type;
  final String? overview;
  final int? productionYear;
  final double? communityRating;
  final String? officialRating;
  final int? runTimeTicks;
  final List<String> genres;
  final String? primaryImageTag;
  final List<String> backdropImageTags;
  final int playbackPositionTicks;
  final bool played;
  final bool isFavorite;
  final int playCount;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? seriesName;
  final String? seriesId;
  final String? parentId;

  const MediaItem({
    required this.id, required this.name, required this.type,
    this.overview, this.productionYear, this.communityRating,
    this.officialRating, this.runTimeTicks, this.genres = const [],
    this.primaryImageTag, this.backdropImageTags = const [],
    this.playbackPositionTicks = 0, this.played = false,
    this.isFavorite = false, this.playCount = 0,
    this.seasonNumber, this.episodeNumber, this.seriesName,
    this.seriesId, this.parentId,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final imageTags = (json['ImageTags'] as Map?)?.cast<String, dynamic>() ?? {};
    final backdropTags = (json['BackdropImageTags'] as List<dynamic>?)?.cast<String>() ?? [];
    final userData = json['UserData'] as Map<String, dynamic>?;

    return MediaItem(
      id: json['Id'] as String,
      name: json['Name'] as String? ?? '',
      type: MediaType.fromString(json['Type'] as String?),
      overview: json['Overview'] as String?,
      productionYear: json['ProductionYear'] as int?,
      communityRating: (json['CommunityRating'] as num?)?.toDouble(),
      officialRating: json['OfficialRating'] as String?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      genres: (json['Genres'] as List<dynamic>?)?.cast<String>() ?? const [],
      primaryImageTag: imageTags['Primary'] as String?,
      backdropImageTags: backdropTags,
      playbackPositionTicks: (userData?['PlaybackPositionTicks'] as int?) ?? 0,
      played: (userData?['Played'] as bool?) ?? false,
      isFavorite: (userData?['IsFavorite'] as bool?) ?? false,
      playCount: (userData?['PlayCount'] as int?) ?? 0,
      seasonNumber: json['ParentIndexNumber'] as int?,
      episodeNumber: json['IndexNumber'] as int?,
      seriesName: json['SeriesName'] as String?,
      seriesId: json['SeriesId'] as String?,
      parentId: json['ParentId'] as String?,
    );
  }

  String get runtimeFormatted {
    if (runTimeTicks == null) return '';
    final totalMinutes = runTimeTicks! ~/ 600000000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  double get progressPercent {
    if (runTimeTicks == null || runTimeTicks == 0) return 0.0;
    return playbackPositionTicks / runTimeTicks!;
  }

  bool get hasProgress => playbackPositionTicks > 0 && !played;
}

class PaginatedResult {
  final List<MediaItem> items;
  final int totalCount;
  final int startIndex;

  const PaginatedResult({required this.items, required this.totalCount, required this.startIndex});

  factory PaginatedResult.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['Items'] as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: itemsList,
      totalCount: json['TotalRecordCount'] as int? ?? 0,
      startIndex: json['StartIndex'] as int? ?? 0,
    );
  }

  bool get hasMore => startIndex + items.length < totalCount;
}
