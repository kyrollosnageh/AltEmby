# Phase 2 -- Library: Home Screen, Browsing, Detail Pages, Image Caching, Search

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully navigable library experience -- home screen with "continue watching" and "recently added" rows, library browsing with pagination/infinite scroll, movie and series detail pages, server-side search, and aggressive image caching.

**Architecture:** Extend the existing clean architecture. New `library` feature with repository + paginated providers. New `details` and `search` features. ShellRoute with bottom nav bar for main app navigation. All data fetched from Emby API with pagination (50 items per page). Images requested at appropriate sizes via URL parameters.

**Tech Stack:** Flutter, Riverpod, Dio (existing EmbyApiClient), GoRouter ShellRoute, cached_network_image, shimmer

---

## File Structure

```
lib/
├── shared/
│   ├── models/
│   │   └── media_item.dart              # Universal model for all Emby items
│   └── widgets/
│       ├── media_card.dart              # Poster card with title overlay
│       ├── media_grid.dart              # Responsive grid with infinite scroll
│       ├── media_row.dart               # Horizontal scrollable row for home screen
│       ├── shimmer_grid.dart            # Loading placeholder grid
│       └── emby_image.dart              # CachedNetworkImage wrapper with size params
├── core/
│   └── utils/
│       └── image_utils.dart             # Build Emby image URLs with sizing + tags
├── features/
│   ├── home/
│   │   ├── data/
│   │   │   └── home_repository.dart     # Fetch continue watching, recent, recommendations
│   │   └── presentation/
│   │       ├── home_screen.dart          # MODIFY: replace placeholder with real home
│   │       ├── providers/
│   │       │   └── home_providers.dart   # FutureProviders for home rows
│   │       └── widgets/
│   │           └── home_section.dart     # Section header + horizontal row
│   ├── library/
│   │   ├── data/
│   │   │   └── library_repository.dart  # Paginated item fetching, sorting, filtering
│   │   └── presentation/
│   │       ├── library_screen.dart       # Tab-based library with grid view
│   │       └── providers/
│   │           └── library_providers.dart # Paginated state notifier
│   ├── details/
│   │   ├── data/
│   │   │   └── details_repository.dart  # Fetch item details, seasons, episodes
│   │   └── presentation/
│   │       ├── movie_detail_screen.dart  # Movie detail page
│   │       ├── series_detail_screen.dart # Series with season/episode list
│   │       └── providers/
│   │           └── details_providers.dart
│   └── search/
│       ├── data/
│       │   └── search_repository.dart    # Server-side search
│       └── presentation/
│           ├── search_screen.dart        # Search bar + results
│           └── providers/
│               └── search_providers.dart
├── app_router.dart                       # MODIFY: add ShellRoute + new routes
└── app_shell.dart                        # Bottom nav bar scaffold
```

```
test/
├── shared/
│   └── models/
│       └── media_item_test.dart
├── features/
│   ├── home/
│   │   └── data/
│   │       └── home_repository_test.dart
│   ├── library/
│   │   └── data/
│   │       └── library_repository_test.dart
│   ├── details/
│   │   └── data/
│   │       └── details_repository_test.dart
│   └── search/
│       └── data/
│           └── search_repository_test.dart
└── widget/
    ├── media_card_test.dart
    └── search_screen_test.dart
```

---

### Task 1: Add Missing Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add cached_network_image and shimmer to pubspec.yaml**

Add these two lines to the `dependencies:` section in `pubspec.yaml`, after the existing dependencies:

```yaml
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
```

- [ ] **Step 2: Run pub get**

```bash
flutter pub get
```

Expected: resolves successfully.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add cached_network_image and shimmer dependencies"
```

---

### Task 2: MediaItem Model

**Files:**
- Create: `lib/shared/models/media_item.dart`
- Create: `test/shared/models/media_item_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/shared/models/media_item_test.dart

import 'package:altemby/shared/models/media_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaItem', () {
    test('parses movie from Emby JSON', () {
      final json = {
        'Id': 'movie-1',
        'Name': 'Inception',
        'Type': 'Movie',
        'Overview': 'A thief who steals secrets...',
        'ProductionYear': 2010,
        'CommunityRating': 8.8,
        'OfficialRating': 'PG-13',
        'RunTimeTicks': 88800000000,
        'Genres': ['Action', 'Sci-Fi'],
        'ImageTags': {'Primary': 'tag-abc'},
        'BackdropImageTags': ['tag-bd1'],
        'UserData': {
          'PlaybackPositionTicks': 50000000000,
          'Played': false,
          'IsFavorite': false,
          'PlayCount': 0,
        },
      };

      final item = MediaItem.fromJson(json);

      expect(item.id, 'movie-1');
      expect(item.name, 'Inception');
      expect(item.type, MediaType.movie);
      expect(item.overview, 'A thief who steals secrets...');
      expect(item.productionYear, 2010);
      expect(item.communityRating, 8.8);
      expect(item.officialRating, 'PG-13');
      expect(item.runTimeTicks, 88800000000);
      expect(item.genres, ['Action', 'Sci-Fi']);
      expect(item.primaryImageTag, 'tag-abc');
      expect(item.backdropImageTags, ['tag-bd1']);
      expect(item.playbackPositionTicks, 50000000000);
      expect(item.played, false);
    });

    test('parses series from Emby JSON', () {
      final json = {
        'Id': 'series-1',
        'Name': 'Breaking Bad',
        'Type': 'Series',
        'ProductionYear': 2008,
        'ImageTags': {'Primary': 'tag-bb'},
        'BackdropImageTags': [],
      };

      final item = MediaItem.fromJson(json);

      expect(item.id, 'series-1');
      expect(item.name, 'Breaking Bad');
      expect(item.type, MediaType.series);
    });

    test('parses episode from Emby JSON', () {
      final json = {
        'Id': 'ep-1',
        'Name': 'Pilot',
        'Type': 'Episode',
        'ParentIndexNumber': 1,
        'IndexNumber': 1,
        'SeriesName': 'Breaking Bad',
        'SeriesId': 'series-1',
        'ImageTags': {},
        'BackdropImageTags': [],
      };

      final item = MediaItem.fromJson(json);

      expect(item.type, MediaType.episode);
      expect(item.seasonNumber, 1);
      expect(item.episodeNumber, 1);
      expect(item.seriesName, 'Breaking Bad');
      expect(item.seriesId, 'series-1');
    });

    test('runtimeFormatted returns human-readable duration', () {
      final item = MediaItem.fromJson({
        'Id': '1',
        'Name': 'Test',
        'Type': 'Movie',
        'RunTimeTicks': 72000000000, // 2 hours
        'ImageTags': {},
        'BackdropImageTags': [],
      });

      expect(item.runtimeFormatted, '2h 0m');
    });

    test('progressPercent calculates correctly', () {
      final item = MediaItem.fromJson({
        'Id': '1',
        'Name': 'Test',
        'Type': 'Movie',
        'RunTimeTicks': 100000000000,
        'ImageTags': {},
        'BackdropImageTags': [],
        'UserData': {
          'PlaybackPositionTicks': 50000000000,
          'Played': false,
        },
      });

      expect(item.progressPercent, 0.5);
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'Id': 'min-1',
        'Name': 'Minimal',
        'Type': 'Movie',
        'ImageTags': {},
        'BackdropImageTags': [],
      };

      final item = MediaItem.fromJson(json);

      expect(item.overview, isNull);
      expect(item.productionYear, isNull);
      expect(item.communityRating, isNull);
      expect(item.runTimeTicks, isNull);
      expect(item.genres, isEmpty);
      expect(item.playbackPositionTicks, 0);
      expect(item.played, false);
      expect(item.progressPercent, 0.0);
    });
  });

  group('PaginatedResult', () {
    test('parses Emby paginated response', () {
      final json = {
        'Items': [
          {
            'Id': '1',
            'Name': 'Item 1',
            'Type': 'Movie',
            'ImageTags': {},
            'BackdropImageTags': [],
          },
        ],
        'TotalRecordCount': 100,
        'StartIndex': 0,
      };

      final result = PaginatedResult.fromJson(json);

      expect(result.items.length, 1);
      expect(result.totalCount, 100);
      expect(result.startIndex, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/shared/models/media_item_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement MediaItem**

```dart
// lib/shared/models/media_item.dart

enum MediaType {
  movie,
  series,
  season,
  episode,
  audio,
  musicAlbum,
  musicArtist,
  audioBook,
  boxSet,
  playlist,
  folder,
  unknown;

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

  // Episode-specific
  final int? seasonNumber;
  final int? episodeNumber;
  final String? seriesName;
  final String? seriesId;

  // Season-specific
  final String? parentId;

  const MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.overview,
    this.productionYear,
    this.communityRating,
    this.officialRating,
    this.runTimeTicks,
    this.genres = const [],
    this.primaryImageTag,
    this.backdropImageTags = const [],
    this.playbackPositionTicks = 0,
    this.played = false,
    this.isFavorite = false,
    this.playCount = 0,
    this.seasonNumber,
    this.episodeNumber,
    this.seriesName,
    this.seriesId,
    this.parentId,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final imageTags = json['ImageTags'] as Map<String, dynamic>? ?? {};
    final backdropTags = (json['BackdropImageTags'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
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
      genres:
          (json['Genres'] as List<dynamic>?)?.cast<String>() ?? const [],
      primaryImageTag: imageTags['Primary'] as String?,
      backdropImageTags: backdropTags,
      playbackPositionTicks:
          (userData?['PlaybackPositionTicks'] as int?) ?? 0,
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

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.startIndex,
  });

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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/shared/models/media_item_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/media_item.dart test/shared/models/media_item_test.dart
git commit -m "feat: add MediaItem model with Emby JSON parsing"
```

---

### Task 3: Image Utilities

**Files:**
- Create: `lib/core/utils/image_utils.dart`

- [ ] **Step 1: Create image URL builder**

```dart
// lib/core/utils/image_utils.dart

import 'package:altemby/core/api/api_endpoints.dart';

class ImageUtils {
  ImageUtils._();

  /// Build a full URL for an Emby item image.
  ///
  /// [baseUrl] - The Emby server base URL
  /// [itemId] - The item's ID
  /// [imageType] - 'Primary', 'Backdrop', 'Thumb', etc.
  /// [tag] - Image cache tag from item's ImageTags (enables HTTP caching)
  /// [maxWidth] - Request image scaled to this max width
  /// [maxHeight] - Request image scaled to this max height
  /// [index] - For backdrops, which index (0-based)
  static String itemImageUrl({
    required String baseUrl,
    required String itemId,
    String imageType = 'Primary',
    String? tag,
    int? maxWidth,
    int? maxHeight,
    int? index,
  }) {
    final path = ApiEndpoints.itemImage(itemId, imageType, index: index);
    final params = <String, String>{
      if (tag != null) 'tag': tag,
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (maxHeight != null) 'maxHeight': maxHeight.toString(),
      'quality': '90',
    };
    if (params.isEmpty) return '$baseUrl$path';
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$baseUrl$path?$query';
  }

  /// Thumbnail size for grid/list views (poster ~300px wide)
  static String thumbnailUrl({
    required String baseUrl,
    required String itemId,
    String? tag,
  }) {
    return itemImageUrl(
      baseUrl: baseUrl,
      itemId: itemId,
      tag: tag,
      maxWidth: 300,
    );
  }

  /// Medium size for detail page posters (~500px wide)
  static String posterUrl({
    required String baseUrl,
    required String itemId,
    String? tag,
  }) {
    return itemImageUrl(
      baseUrl: baseUrl,
      itemId: itemId,
      tag: tag,
      maxWidth: 500,
    );
  }

  /// Full-width backdrop for detail pages
  static String backdropUrl({
    required String baseUrl,
    required String itemId,
    String? tag,
    int index = 0,
  }) {
    return itemImageUrl(
      baseUrl: baseUrl,
      itemId: itemId,
      imageType: 'Backdrop',
      tag: tag,
      maxWidth: 1280,
      index: index,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/utils/image_utils.dart
git commit -m "feat: add ImageUtils for Emby image URL construction"
```

---

### Task 4: EmbyImage Widget and MediaCard Widget

**Files:**
- Create: `lib/shared/widgets/emby_image.dart`
- Create: `lib/shared/widgets/media_card.dart`
- Create: `lib/shared/widgets/shimmer_grid.dart`
- Create: `test/widget/media_card_test.dart`

- [ ] **Step 1: Write test for MediaCard**

```dart
// test/widget/media_card_test.dart

import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaCard', () {
    final testItem = MediaItem.fromJson({
      'Id': 'test-1',
      'Name': 'Test Movie',
      'Type': 'Movie',
      'ProductionYear': 2023,
      'ImageTags': {'Primary': 'tag-123'},
      'BackdropImageTags': [],
    });

    testWidgets('displays item name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(
                item: testItem,
                baseUrl: 'https://emby.test',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Movie'), findsOneWidget);
    });

    testWidgets('displays year when available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(
                item: testItem,
                baseUrl: 'https://emby.test',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(
                item: testItem,
                baseUrl: 'https://emby.test',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MediaCard));
      expect(tapped, true);
    });

    testWidgets('shows progress bar for in-progress items', (tester) async {
      final inProgressItem = MediaItem.fromJson({
        'Id': 'test-2',
        'Name': 'In Progress',
        'Type': 'Movie',
        'RunTimeTicks': 100000000000,
        'ImageTags': {'Primary': 'tag-123'},
        'BackdropImageTags': [],
        'UserData': {
          'PlaybackPositionTicks': 50000000000,
          'Played': false,
        },
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(
                item: inProgressItem,
                baseUrl: 'https://emby.test',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/media_card_test.dart
```

- [ ] **Step 3: Create EmbyImage widget**

```dart
// lib/shared/widgets/emby_image.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EmbyImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const EmbyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[700]!,
        child: Container(
          width: width,
          height: height,
          color: Colors.grey[900],
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
```

- [ ] **Step 4: Create MediaCard widget**

```dart
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

  const MediaCard({
    super.key,
    required this.item,
    required this.baseUrl,
    required this.onTap,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUtils.thumbnailUrl(
      baseUrl: baseUrl,
      itemId: item.id,
      tag: item.primaryImageTag,
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster image with progress overlay
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EmbyImage(imageUrl: imageUrl),
                    if (item.hasProgress)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: item.progressPercent,
                          minHeight: 3,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    if (item.played)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // Year or subtitle
            if (item.productionYear != null)
              Text(
                '${item.productionYear}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create ShimmerGrid loading placeholder**

```dart
// lib/shared/widgets/shimmer_grid.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;

  const ShimmerGrid({
    super.key,
    this.itemCount = 12,
    this.childAspectRatio = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount(context),
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 6;
    if (width > 600) return 4;
    return 3;
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/widget/media_card_test.dart
```

Expected: all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/ lib/core/utils/image_utils.dart test/widget/media_card_test.dart
git commit -m "feat: add EmbyImage, MediaCard, and ShimmerGrid widgets"
```

---

### Task 5: Library Repository

**Files:**
- Create: `lib/features/library/data/library_repository.dart`
- Create: `test/features/library/data/library_repository_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/features/library/data/library_repository_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/library/data/library_repository.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

void main() {
  late MockEmbyApiClient mockClient;
  late LibraryRepository repo;

  setUp(() {
    mockClient = MockEmbyApiClient();
    repo = LibraryRepository(apiClient: mockClient);
  });

  group('getItems', () {
    test('fetches paginated items with correct parameters', () async {
      when(() => mockClient.get(
            '/Users/user-1/Items',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [
              {
                'Id': 'm1',
                'Name': 'Movie 1',
                'Type': 'Movie',
                'ImageTags': {},
                'BackdropImageTags': [],
              },
            ],
            'TotalRecordCount': 100,
            'StartIndex': 0,
          });

      final result = await repo.getItems(
        userId: 'user-1',
        includeTypes: 'Movie',
        startIndex: 0,
        limit: 50,
      );

      expect(result.items.length, 1);
      expect(result.totalCount, 100);
      expect(result.items.first.name, 'Movie 1');

      verify(() => mockClient.get(
            '/Users/user-1/Items',
            queryParameters: {
              'IncludeItemTypes': 'Movie',
              'Recursive': true,
              'StartIndex': 0,
              'Limit': 50,
              'Fields': 'Overview,Genres,RunTimeTicks,UserData,ImageTags',
              'SortBy': 'SortName',
              'SortOrder': 'Ascending',
              'EnableImageTypes': 'Primary,Backdrop,Thumb',
              'ImageTypeLimit': 1,
            },
          )).called(1);
    });

    test('applies sorting and filtering', () async {
      when(() => mockClient.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [],
            'TotalRecordCount': 0,
            'StartIndex': 0,
          });

      await repo.getItems(
        userId: 'user-1',
        includeTypes: 'Movie',
        sortBy: 'DateCreated',
        sortOrder: 'Descending',
        genres: 'Action',
        isPlayed: false,
      );

      verify(() => mockClient.get(
            '/Users/user-1/Items',
            queryParameters: {
              'IncludeItemTypes': 'Movie',
              'Recursive': true,
              'StartIndex': 0,
              'Limit': 50,
              'Fields': 'Overview,Genres,RunTimeTicks,UserData,ImageTags',
              'SortBy': 'DateCreated',
              'SortOrder': 'Descending',
              'EnableImageTypes': 'Primary,Backdrop,Thumb',
              'ImageTypeLimit': 1,
              'Genres': 'Action',
              'IsPlayed': false,
            },
          )).called(1);
    });
  });

  group('getUserViews', () {
    test('fetches library root folders', () async {
      when(() => mockClient.get('/Users/user-1/Views'))
          .thenAnswer((_) async => {
                'Items': [
                  {
                    'Id': 'lib-1',
                    'Name': 'Movies',
                    'Type': 'CollectionFolder',
                    'CollectionType': 'movies',
                    'ImageTags': {},
                    'BackdropImageTags': [],
                  },
                  {
                    'Id': 'lib-2',
                    'Name': 'TV Shows',
                    'Type': 'CollectionFolder',
                    'CollectionType': 'tvshows',
                    'ImageTags': {},
                    'BackdropImageTags': [],
                  },
                ],
                'TotalRecordCount': 2,
              });

      final views = await repo.getUserViews(userId: 'user-1');

      expect(views.length, 2);
      expect(views[0].name, 'Movies');
      expect(views[1].name, 'TV Shows');
    });
  });

  group('getSeasons', () {
    test('fetches seasons for a series', () async {
      when(() => mockClient.get(
            '/Shows/series-1/Seasons',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [
              {
                'Id': 'season-1',
                'Name': 'Season 1',
                'Type': 'Season',
                'IndexNumber': 1,
                'ImageTags': {},
                'BackdropImageTags': [],
              },
            ],
            'TotalRecordCount': 1,
          });

      final seasons = await repo.getSeasons(
        seriesId: 'series-1',
        userId: 'user-1',
      );

      expect(seasons.length, 1);
      expect(seasons.first.name, 'Season 1');
    });
  });

  group('getEpisodes', () {
    test('fetches episodes for a series and season', () async {
      when(() => mockClient.get(
            '/Shows/series-1/Episodes',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [
              {
                'Id': 'ep-1',
                'Name': 'Pilot',
                'Type': 'Episode',
                'IndexNumber': 1,
                'ParentIndexNumber': 1,
                'ImageTags': {},
                'BackdropImageTags': [],
              },
            ],
            'TotalRecordCount': 1,
          });

      final episodes = await repo.getEpisodes(
        seriesId: 'series-1',
        seasonId: 'season-1',
        userId: 'user-1',
      );

      expect(episodes.length, 1);
      expect(episodes.first.name, 'Pilot');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/library/data/library_repository_test.dart
```

- [ ] **Step 3: Implement LibraryRepository**

```dart
// lib/features/library/data/library_repository.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

class LibraryRepository {
  final EmbyApiClient _apiClient;

  LibraryRepository({required EmbyApiClient apiClient})
      : _apiClient = apiClient;

  static const _defaultFields =
      'Overview,Genres,RunTimeTicks,UserData,ImageTags';

  /// Fetch paginated items from user's library.
  Future<PaginatedResult> getItems({
    required String userId,
    String? includeTypes,
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? parentId,
    String? genres,
    String? years,
    bool? isPlayed,
    String? searchTerm,
  }) async {
    final params = <String, dynamic>{
      if (includeTypes != null) 'IncludeItemTypes': includeTypes,
      'Recursive': true,
      'StartIndex': startIndex,
      'Limit': limit,
      'Fields': _defaultFields,
      'SortBy': sortBy,
      'SortOrder': sortOrder,
      'EnableImageTypes': 'Primary,Backdrop,Thumb',
      'ImageTypeLimit': 1,
      if (parentId != null) 'ParentId': parentId,
      if (genres != null) 'Genres': genres,
      if (years != null) 'Years': years,
      if (isPlayed != null) 'IsPlayed': isPlayed,
      if (searchTerm != null) 'SearchTerm': searchTerm,
    };

    final data = await _apiClient.get(
      ApiEndpoints.userItems(userId),
      queryParameters: params,
    );
    return PaginatedResult.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch the user's library views (top-level folders).
  Future<List<MediaItem>> getUserViews({required String userId}) async {
    final data = await _apiClient.get('/Users/$userId/Views');
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch seasons for a TV series.
  Future<List<MediaItem>> getSeasons({
    required String seriesId,
    required String userId,
  }) async {
    final data = await _apiClient.get(
      ApiEndpoints.showSeasons(seriesId),
      queryParameters: {
        'UserId': userId,
        'Fields': _defaultFields,
        'EnableImageTypes': 'Primary',
        'ImageTypeLimit': 1,
      },
    );
    final items =
        (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch episodes for a TV series, optionally filtered by season.
  Future<List<MediaItem>> getEpisodes({
    required String seriesId,
    required String userId,
    String? seasonId,
  }) async {
    final data = await _apiClient.get(
      ApiEndpoints.showEpisodes(seriesId),
      queryParameters: {
        'UserId': userId,
        'Fields': _defaultFields,
        'EnableImageTypes': 'Primary,Backdrop',
        'ImageTypeLimit': 1,
        if (seasonId != null) 'SeasonId': seasonId,
      },
    );
    final items =
        (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single item's full details.
  Future<MediaItem> getItemDetails({
    required String itemId,
    required String userId,
  }) async {
    final data = await _apiClient.get(
      ApiEndpoints.userItem(userId, itemId),
      queryParameters: {
        'Fields':
            'Overview,Genres,Studios,People,RunTimeTicks,UserData,ImageTags,MediaSources,Chapters,ExternalUrls,ProviderIds',
      },
    );
    return MediaItem.fromJson(data as Map<String, dynamic>);
  }

  /// Fetch similar/recommended items.
  Future<List<MediaItem>> getSimilarItems({
    required String itemId,
    int limit = 12,
  }) async {
    final data = await _apiClient.get(
      '/Items/$itemId/Similar',
      queryParameters: {
        'Limit': limit,
        'Fields': 'Overview,UserData,ImageTags',
        'EnableImageTypes': 'Primary',
        'ImageTypeLimit': 1,
      },
    );
    final items =
        (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/library/data/library_repository_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/library/ test/features/library/
git commit -m "feat: add LibraryRepository with paginated item fetching"
```

---

### Task 6: Home Repository

**Files:**
- Create: `lib/features/home/data/home_repository.dart`
- Create: `test/features/home/data/home_repository_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/features/home/data/home_repository_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/home/data/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

void main() {
  late MockEmbyApiClient mockClient;
  late HomeRepository repo;

  setUp(() {
    mockClient = MockEmbyApiClient();
    repo = HomeRepository(apiClient: mockClient);
  });

  group('getContinueWatching', () {
    test('fetches resumable items', () async {
      when(() => mockClient.get(
            '/Users/user-1/Items/Resume',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [
              {
                'Id': 'm1',
                'Name': 'Movie 1',
                'Type': 'Movie',
                'RunTimeTicks': 100000000000,
                'ImageTags': {},
                'BackdropImageTags': [],
                'UserData': {
                  'PlaybackPositionTicks': 50000000000,
                  'Played': false,
                },
              },
            ],
            'TotalRecordCount': 1,
          });

      final items = await repo.getContinueWatching(userId: 'user-1');

      expect(items.length, 1);
      expect(items.first.hasProgress, true);
    });
  });

  group('getRecentlyAdded', () {
    test('fetches recently added items', () async {
      when(() => mockClient.get(
            '/Users/user-1/Items/Latest',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => [
            {
              'Id': 'm2',
              'Name': 'New Movie',
              'Type': 'Movie',
              'ImageTags': {},
              'BackdropImageTags': [],
            },
          ]);

      final items = await repo.getRecentlyAdded(userId: 'user-1');

      expect(items.length, 1);
      expect(items.first.name, 'New Movie');
    });
  });

  group('getNextUp', () {
    test('fetches next up episodes', () async {
      when(() => mockClient.get(
            '/Shows/NextUp',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [
              {
                'Id': 'ep-2',
                'Name': 'Episode 2',
                'Type': 'Episode',
                'SeriesName': 'Show 1',
                'IndexNumber': 2,
                'ParentIndexNumber': 1,
                'ImageTags': {},
                'BackdropImageTags': [],
              },
            ],
            'TotalRecordCount': 1,
          });

      final items = await repo.getNextUp(userId: 'user-1');

      expect(items.length, 1);
      expect(items.first.name, 'Episode 2');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement HomeRepository**

```dart
// lib/features/home/data/home_repository.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

class HomeRepository {
  final EmbyApiClient _apiClient;

  HomeRepository({required EmbyApiClient apiClient})
      : _apiClient = apiClient;

  /// Fetch items the user is currently watching (have progress).
  Future<List<MediaItem>> getContinueWatching({
    required String userId,
    int limit = 20,
  }) async {
    final data = await _apiClient.get(
      '/Users/$userId/Items/Resume',
      queryParameters: {
        'Limit': limit,
        'Recursive': true,
        'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
        'EnableImageTypes': 'Primary,Backdrop,Thumb',
        'ImageTypeLimit': 1,
        'MediaTypes': 'Video',
      },
    );
    final items =
        (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch recently added items.
  /// Note: /Users/{id}/Items/Latest returns a flat array, not wrapped in Items/TotalRecordCount.
  Future<List<MediaItem>> getRecentlyAdded({
    required String userId,
    int limit = 20,
  }) async {
    final data = await _apiClient.get(
      '/Users/$userId/Items/Latest',
      queryParameters: {
        'Limit': limit,
        'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
        'EnableImageTypes': 'Primary,Backdrop',
        'ImageTypeLimit': 1,
        'IncludeItemTypes': 'Movie,Episode',
      },
    );
    // /Items/Latest returns a flat list, not wrapped
    final items = data as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch "next up" episodes for shows the user is watching.
  Future<List<MediaItem>> getNextUp({
    required String userId,
    int limit = 20,
  }) async {
    final data = await _apiClient.get(
      '/Shows/NextUp',
      queryParameters: {
        'UserId': userId,
        'Limit': limit,
        'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
        'EnableImageTypes': 'Primary,Backdrop',
        'ImageTypeLimit': 1,
      },
    );
    final items =
        (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/home/data/home_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/data/ test/features/home/data/
git commit -m "feat: add HomeRepository for continue watching, recently added, next up"
```

---

### Task 7: MediaRow Widget and HomeSection Widget

**Files:**
- Create: `lib/shared/widgets/media_row.dart`
- Create: `lib/features/home/presentation/widgets/home_section.dart`

- [ ] **Step 1: Create MediaRow (horizontal scrollable row of cards)**

```dart
// lib/shared/widgets/media_row.dart

import 'package:flutter/material.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_card.dart';

class MediaRow extends StatelessWidget {
  final List<MediaItem> items;
  final String baseUrl;
  final void Function(MediaItem item) onItemTap;
  final double cardWidth;
  final double height;

  const MediaRow({
    super.key,
    required this.items,
    required this.baseUrl,
    required this.onItemTap,
    this.cardWidth = 140,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return MediaCard(
            item: item,
            baseUrl: baseUrl,
            width: cardWidth,
            onTap: () => onItemTap(item),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Create HomeSection (title + row)**

```dart
// lib/features/home/presentation/widgets/home_section.dart

import 'package:flutter/material.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_row.dart';

class HomeSection extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final String baseUrl;
  final void Function(MediaItem item) onItemTap;

  const HomeSection({
    super.key,
    required this.title,
    required this.items,
    required this.baseUrl,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        MediaRow(
          items: items,
          baseUrl: baseUrl,
          onItemTap: onItemTap,
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/media_row.dart lib/features/home/presentation/widgets/
git commit -m "feat: add MediaRow and HomeSection widgets"
```

---

### Task 8: Home Providers and Rebuild HomeScreen

**Files:**
- Create: `lib/features/home/presentation/providers/home_providers.dart`
- Modify: `lib/features/home/presentation/home_screen.dart`
- Modify: `lib/features/auth/presentation/providers/auth_providers.dart` (add library/home repository providers)

- [ ] **Step 1: Add repository providers to auth_providers.dart**

Add these providers at the end of `lib/features/auth/presentation/providers/auth_providers.dart`:

```dart
// Add imports at top:
import 'package:altemby/features/home/data/home_repository.dart';
import 'package:altemby/features/library/data/library_repository.dart';

// Add at bottom, after savedSessionsProvider:

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(apiClient: ref.watch(embyApiClientProvider)),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(apiClient: ref.watch(embyApiClientProvider)),
);
```

- [ ] **Step 2: Create home providers**

```dart
// lib/features/home/presentation/providers/home_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/shared/models/media_item.dart';

final continueWatchingProvider = FutureProvider<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];

  final repo = ref.watch(homeRepositoryProvider);
  return repo.getContinueWatching(userId: authState.session.userId);
});

final recentlyAddedProvider = FutureProvider<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];

  final repo = ref.watch(homeRepositoryProvider);
  return repo.getRecentlyAdded(userId: authState.session.userId);
});

final nextUpProvider = FutureProvider<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];

  final repo = ref.watch(homeRepositoryProvider);
  return repo.getNextUp(userId: authState.session.userId);
});
```

- [ ] **Step 3: Rebuild HomeScreen**

Replace `lib/features/home/presentation/home_screen.dart` entirely:

```dart
// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/home/presentation/providers/home_providers.dart';
import 'package:altemby/features/home/presentation/widgets/home_section.dart';
import 'package:altemby/shared/models/media_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching = ref.watch(continueWatchingProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final nextUp = ref.watch(nextUpProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(continueWatchingProvider);
          ref.invalidate(recentlyAddedProvider);
          ref.invalidate(nextUpProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('AltEmby'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.switch_account),
                  tooltip: 'Switch User',
                  onPressed: () => context.push('/user-select'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSection(
                    context,
                    title: 'Continue Watching',
                    asyncValue: continueWatching,
                    baseUrl: baseUrl,
                  ),
                  _buildSection(
                    context,
                    title: 'Next Up',
                    asyncValue: nextUp,
                    baseUrl: baseUrl,
                  ),
                  _buildSection(
                    context,
                    title: 'Recently Added',
                    asyncValue: recentlyAdded,
                    baseUrl: baseUrl,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required AsyncValue<List<MediaItem>> asyncValue,
    required String baseUrl,
  }) {
    return asyncValue.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) => HomeSection(
        title: title,
        items: items,
        baseUrl: baseUrl,
        onItemTap: (item) => context.push('/details/${item.id}'),
      ),
    );
  }
}
```

- [ ] **Step 4: Run flutter analyze**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/ lib/features/auth/presentation/providers/auth_providers.dart
git commit -m "feat: rebuild HomeScreen with continue watching, recently added, next up"
```

---

### Task 9: Library Providers and Library Screen

**Files:**
- Create: `lib/features/library/presentation/providers/library_providers.dart`
- Create: `lib/shared/widgets/media_grid.dart`
- Create: `lib/features/library/presentation/library_screen.dart`

- [ ] **Step 1: Create MediaGrid (responsive grid with infinite scroll)**

```dart
// lib/shared/widgets/media_grid.dart

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

  const MediaGrid({
    super.key,
    required this.items,
    required this.baseUrl,
    required this.onItemTap,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
  });

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
    if (widget.items.isEmpty && widget.isLoading) {
      return const ShimmerGrid();
    }

    if (widget.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No items found', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount(context),
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = widget.items[index];
        return MediaCard(
          item: item,
          baseUrl: widget.baseUrl,
          onTap: () => widget.onItemTap(item),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Create library providers**

```dart
// lib/features/library/presentation/providers/library_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/shared/models/media_item.dart';

// Current library type filter
final libraryTypeProvider = StateProvider<String>((ref) => 'Movie');

// Sort settings
final librarySortByProvider = StateProvider<String>((ref) => 'SortName');
final librarySortOrderProvider = StateProvider<String>((ref) => 'Ascending');

// Paginated library state
class LibraryState {
  final List<MediaItem> items;
  final int totalCount;
  final bool isLoading;
  final String? error;

  const LibraryState({
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
  });

  LibraryState copyWith({
    List<MediaItem>? items,
    int? totalCount,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasMore => items.length < totalCount;
}

final libraryStateProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(ref);
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Ref _ref;

  LibraryNotifier(this._ref) : super(const LibraryState());

  Future<void> loadInitial() async {
    final authState = _ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;

    state = state.copyWith(isLoading: true, items: [], error: null);

    try {
      final repo = _ref.read(libraryRepositoryProvider);
      final type = _ref.read(libraryTypeProvider);
      final sortBy = _ref.read(librarySortByProvider);
      final sortOrder = _ref.read(librarySortOrderProvider);

      final result = await repo.getItems(
        userId: authState.session.userId,
        includeTypes: type,
        startIndex: 0,
        limit: 50,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      state = LibraryState(
        items: result.items,
        totalCount: result.totalCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final authState = _ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;

    state = state.copyWith(isLoading: true);

    try {
      final repo = _ref.read(libraryRepositoryProvider);
      final type = _ref.read(libraryTypeProvider);
      final sortBy = _ref.read(librarySortByProvider);
      final sortOrder = _ref.read(librarySortOrderProvider);

      final result = await repo.getItems(
        userId: authState.session.userId,
        includeTypes: type,
        startIndex: state.items.length,
        limit: 50,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      state = LibraryState(
        items: [...state.items, ...result.items],
        totalCount: result.totalCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

- [ ] **Step 3: Create LibraryScreen**

```dart
// lib/features/library/presentation/library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/library/presentation/providers/library_providers.dart';
import 'package:altemby/shared/widgets/media_grid.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryStateProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryStateProvider);
    final currentType = ref.watch(libraryTypeProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _TypeChip(label: 'Movies', type: 'Movie', current: currentType),
                const SizedBox(width: 8),
                _TypeChip(label: 'Shows', type: 'Series', current: currentType),
                const SizedBox(width: 8),
                _TypeChip(label: 'Music', type: 'MusicAlbum', current: currentType),
                const SizedBox(width: 8),
                _TypeChip(label: 'Collections', type: 'BoxSet', current: currentType),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (value) {
              final parts = value.split(':');
              ref.read(librarySortByProvider.notifier).state = parts[0];
              ref.read(librarySortOrderProvider.notifier).state = parts[1];
              ref.read(libraryStateProvider.notifier).loadInitial();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'SortName:Ascending', child: Text('Name (A-Z)')),
              const PopupMenuItem(value: 'SortName:Descending', child: Text('Name (Z-A)')),
              const PopupMenuItem(value: 'DateCreated:Descending', child: Text('Date Added')),
              const PopupMenuItem(value: 'CommunityRating:Descending', child: Text('Rating')),
              const PopupMenuItem(value: 'ProductionYear:Descending', child: Text('Year')),
              const PopupMenuItem(value: 'Random:Ascending', child: Text('Random')),
            ],
          ),
        ],
      ),
      body: libraryState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${libraryState.error}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.read(libraryStateProvider.notifier).loadInitial(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : MediaGrid(
              items: libraryState.items,
              baseUrl: baseUrl,
              isLoading: libraryState.isLoading,
              hasMore: libraryState.hasMore,
              onLoadMore: () =>
                  ref.read(libraryStateProvider.notifier).loadMore(),
              onItemTap: (item) => context.push('/details/${item.id}'),
            ),
    );
  }
}

class _TypeChip extends ConsumerWidget {
  final String label;
  final String type;
  final String current;

  const _TypeChip({
    required this.label,
    required this.type,
    required this.current,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = type == current;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(libraryTypeProvider.notifier).state = type;
        ref.read(libraryStateProvider.notifier).loadInitial();
      },
    );
  }
}
```

- [ ] **Step 4: Run flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/library/presentation/ lib/shared/widgets/media_grid.dart
git commit -m "feat: add LibraryScreen with paginated grid and type/sort filters"
```

---

### Task 10: Details Providers and Movie Detail Screen

**Files:**
- Create: `lib/features/details/presentation/providers/details_providers.dart`
- Create: `lib/features/details/presentation/movie_detail_screen.dart`

- [ ] **Step 1: Create details providers**

```dart
// lib/features/details/presentation/providers/details_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/shared/models/media_item.dart';

final itemDetailProvider =
    FutureProvider.family<MediaItem, String>((ref, itemId) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) throw Exception('Not authenticated');

  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getItemDetails(
    itemId: itemId,
    userId: authState.session.userId,
  );
});

final similarItemsProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, itemId) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getSimilarItems(itemId: itemId);
});

final seasonsProvider =
    FutureProvider.family<List<MediaItem>, String>((ref, seriesId) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) throw Exception('Not authenticated');

  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getSeasons(
    seriesId: seriesId,
    userId: authState.session.userId,
  );
});

final episodesProvider = FutureProvider.family<List<MediaItem>,
    ({String seriesId, String seasonId})>((ref, params) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) throw Exception('Not authenticated');

  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getEpisodes(
    seriesId: params.seriesId,
    seasonId: params.seasonId,
    userId: authState.session.userId,
  );
});
```

- [ ] **Step 2: Create MovieDetailScreen**

```dart
// lib/features/details/presentation/movie_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/details/presentation/providers/details_providers.dart';
import 'package:altemby/features/home/presentation/widgets/home_section.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class MovieDetailScreen extends ConsumerWidget {
  final String itemId;

  const MovieDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(itemDetailProvider(itemId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (item) => _buildContent(context, ref, item, baseUrl),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    String baseUrl,
  ) {
    final similarAsync = ref.watch(similarItemsProvider(itemId));

    return CustomScrollView(
      slivers: [
        // Backdrop header
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: item.backdropImageTags.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      EmbyImage(
                        imageUrl: ImageUtils.backdropUrl(
                          baseUrl: baseUrl,
                          itemId: item.id,
                          tag: item.backdropImageTags.first,
                        ),
                      ),
                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(color: Colors.grey[900]),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Metadata row
                Wrap(
                  spacing: 12,
                  children: [
                    if (item.productionYear != null)
                      Text('${item.productionYear}',
                          style: const TextStyle(color: Colors.grey)),
                    if (item.runtimeFormatted.isNotEmpty)
                      Text(item.runtimeFormatted,
                          style: const TextStyle(color: Colors.grey)),
                    if (item.officialRating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.officialRating!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                    if (item.communityRating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            item.communityRating!.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Genres
                if (item.genres.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: item.genres
                        .map((g) => Chip(
                              label: Text(g, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                if (item.genres.isNotEmpty) const SizedBox(height: 16),

                // Overview
                if (item.overview != null && item.overview!.isNotEmpty)
                  Text(
                    item.overview!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[300],
                          height: 1.5,
                        ),
                  ),
                const SizedBox(height: 24),

                // Similar items
                similarAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (similar) => HomeSection(
                    title: 'Similar',
                    items: similar,
                    baseUrl: baseUrl,
                    onItemTap: (item) => context.push('/details/${item.id}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/details/
git commit -m "feat: add MovieDetailScreen with backdrop, metadata, and similar items"
```

---

### Task 11: Series Detail Screen

**Files:**
- Create: `lib/features/details/presentation/series_detail_screen.dart`

- [ ] **Step 1: Create SeriesDetailScreen**

```dart
// lib/features/details/presentation/series_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/details/presentation/providers/details_providers.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const SeriesDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  String? _selectedSeasonId;

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemDetailProvider(widget.itemId));
    final seasonsAsync = ref.watch(seasonsProvider(widget.itemId));
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (item) => _buildContent(context, item, seasonsAsync, baseUrl),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MediaItem item,
    AsyncValue<List<MediaItem>> seasonsAsync,
    String baseUrl,
  ) {
    return CustomScrollView(
      slivers: [
        // Backdrop
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              item.name,
              style: const TextStyle(fontSize: 16),
            ),
            background: item.backdropImageTags.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      EmbyImage(
                        imageUrl: ImageUtils.backdropUrl(
                          baseUrl: baseUrl,
                          itemId: item.id,
                          tag: item.backdropImageTags.first,
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(color: Colors.grey[900]),
          ),
        ),

        // Info + overview
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata
                Wrap(
                  spacing: 12,
                  children: [
                    if (item.productionYear != null)
                      Text('${item.productionYear}',
                          style: const TextStyle(color: Colors.grey)),
                    if (item.officialRating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.officialRating!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                    if (item.communityRating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(item.communityRating!.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                  ],
                ),
                if (item.overview != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.overview!,
                    style: TextStyle(color: Colors.grey[300], height: 1.5),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Season tabs
        SliverToBoxAdapter(
          child: seasonsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading seasons: $e'),
            data: (seasons) {
              if (seasons.isEmpty) return const SizedBox.shrink();
              _selectedSeasonId ??= seasons.first.id;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: seasons.map((season) {
                        final isSelected = season.id == _selectedSeasonId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(season.name),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedSeasonId = season.id);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),

        // Episodes
        if (_selectedSeasonId != null)
          _EpisodesList(
            seriesId: widget.itemId,
            seasonId: _selectedSeasonId!,
            baseUrl: baseUrl,
          ),
      ],
    );
  }
}

class _EpisodesList extends ConsumerWidget {
  final String seriesId;
  final String seasonId;
  final String baseUrl;

  const _EpisodesList({
    required this.seriesId,
    required this.seasonId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(
      episodesProvider((seriesId: seriesId, seasonId: seasonId)),
    );

    return episodesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        )),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
      data: (episodes) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ep = episodes[index];
            return ListTile(
              leading: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: EmbyImage(
                          imageUrl: ImageUtils.itemImageUrl(
                            baseUrl: baseUrl,
                            itemId: ep.id,
                            imageType: ep.primaryImageTag != null
                                ? 'Primary'
                                : 'Backdrop',
                            tag: ep.primaryImageTag,
                            maxWidth: 240,
                          ),
                        ),
                      ),
                      if (ep.hasProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: ep.progressPercent,
                            minHeight: 3,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              title: Text(
                ep.episodeNumber != null
                    ? '${ep.episodeNumber}. ${ep.name}'
                    : ep.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                ep.runtimeFormatted,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: ep.played
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                  : null,
              onTap: () => context.push('/details/${ep.id}'),
            );
          },
          childCount: episodes.length,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/details/presentation/series_detail_screen.dart
git commit -m "feat: add SeriesDetailScreen with season tabs and episode list"
```

---

### Task 12: Search Feature

**Files:**
- Create: `lib/features/search/data/search_repository.dart`
- Create: `lib/features/search/presentation/providers/search_providers.dart`
- Create: `lib/features/search/presentation/search_screen.dart`
- Create: `test/features/search/data/search_repository_test.dart`

- [ ] **Step 1: Write search repository test**

```dart
// test/features/search/data/search_repository_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/search/data/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

void main() {
  late MockEmbyApiClient mockClient;
  late SearchRepository repo;

  setUp(() {
    mockClient = MockEmbyApiClient();
    repo = SearchRepository(apiClient: mockClient);
  });

  group('search', () {
    test('searches across all types', () async {
      when(() => mockClient.get(
            '/Users/user-1/Items',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => {
            'Items': [
              {
                'Id': 'm1',
                'Name': 'Inception',
                'Type': 'Movie',
                'ImageTags': {},
                'BackdropImageTags': [],
              },
            ],
            'TotalRecordCount': 1,
            'StartIndex': 0,
          });

      final result = await repo.search(
        userId: 'user-1',
        query: 'Inception',
      );

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Inception');

      verify(() => mockClient.get(
            '/Users/user-1/Items',
            queryParameters: {
              'SearchTerm': 'Inception',
              'Recursive': true,
              'IncludeItemTypes': 'Movie,Series,Episode,Audio,MusicAlbum',
              'Limit': 50,
              'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
              'EnableImageTypes': 'Primary',
              'ImageTypeLimit': 1,
            },
          )).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement SearchRepository**

```dart
// lib/features/search/data/search_repository.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

class SearchRepository {
  final EmbyApiClient _apiClient;

  SearchRepository({required EmbyApiClient apiClient})
      : _apiClient = apiClient;

  Future<PaginatedResult> search({
    required String userId,
    required String query,
    int limit = 50,
  }) async {
    final data = await _apiClient.get(
      ApiEndpoints.userItems(userId),
      queryParameters: {
        'SearchTerm': query,
        'Recursive': true,
        'IncludeItemTypes': 'Movie,Series,Episode,Audio,MusicAlbum',
        'Limit': limit,
        'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
        'EnableImageTypes': 'Primary',
        'ImageTypeLimit': 1,
      },
    );
    return PaginatedResult.fromJson(data as Map<String, dynamic>);
  }
}
```

- [ ] **Step 4: Create search providers**

```dart
// lib/features/search/presentation/providers/search_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/search/data/search_repository.dart';
import 'package:altemby/shared/models/media_item.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(apiClient: ref.watch(embyApiClientProvider)),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];

  final repo = ref.watch(searchRepositoryProvider);
  final result = await repo.search(
    userId: authState.session.userId,
    query: query,
  );
  return result.items;
});
```

- [ ] **Step 5: Create SearchScreen**

```dart
// lib/features/search/presentation/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/search/presentation/providers/search_providers.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_grid.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search movies, shows, music...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
          autofocus: true,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? const Center(
              child: Text(
                'Search your library',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => MediaGrid(
                items: items,
                baseUrl: baseUrl,
                onItemTap: (item) =>
                    context.push('/details/${item.id}'),
              ),
            ),
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

```bash
flutter test test/features/search/data/search_repository_test.dart
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/search/ test/features/search/
git commit -m "feat: add search feature with debounced server-side search"
```

---

### Task 13: App Shell (Bottom Navigation) and Router Update

**Files:**
- Create: `lib/app_shell.dart`
- Modify: `lib/app_router.dart`

- [ ] **Step 1: Create AppShell with bottom navigation**

```dart
// lib/app_shell.dart

import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int index) onTabSelected;

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update app_router.dart with ShellRoute and detail routes**

Replace `lib/app_router.dart` entirely:

```dart
// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/app_shell.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/presentation/server_connect_screen.dart';
import 'package:altemby/features/auth/presentation/login_screen.dart';
import 'package:altemby/features/auth/presentation/user_select_screen.dart';
import 'package:altemby/features/details/presentation/movie_detail_screen.dart';
import 'package:altemby/features/details/presentation/series_detail_screen.dart';
import 'package:altemby/features/details/presentation/providers/details_providers.dart';
import 'package:altemby/features/home/presentation/home_screen.dart';
import 'package:altemby/features/library/presentation/library_screen.dart';
import 'package:altemby/features/search/presentation/search_screen.dart';
import 'package:altemby/shared/models/media_item.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute = state.matchedLocation == '/server-connect' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/user-select';

      if (!isAuthenticated && !isAuthRoute) {
        return '/server-connect';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/server-connect',
        builder: (context, state) => const ServerConnectScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/user-select',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserSelectScreen(),
      ),

      // Main app with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) => navigationShell.goBranch(index),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Settings - Coming in Phase 7')),
                ),
              ),
            ],
          ),
        ],
      ),

      // Detail routes (full screen, above shell)
      GoRoute(
        path: '/details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          return _DetailRouter(itemId: itemId);
        },
      ),
    ],
  );
});

/// Routes to MovieDetailScreen or SeriesDetailScreen based on item type.
class _DetailRouter extends ConsumerWidget {
  final String itemId;

  const _DetailRouter({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));

    return itemAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (item) {
        if (item.type == MediaType.series) {
          return SeriesDetailScreen(itemId: itemId);
        }
        return MovieDetailScreen(itemId: itemId);
      },
    );
  }
}
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/app_shell.dart lib/app_router.dart
git commit -m "feat: add bottom nav shell and detail/library/search routes"
```

---

### Task 14: Final Integration Verification

**Files:** None (verification only)

- [ ] **Step 1: Run the full test suite**

```bash
flutter test --reporter expanded
```

Expected: all tests pass.

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Verify the app builds**

```bash
flutter build apk --debug
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Tag the milestone**

```bash
git tag -a v0.2.0-phase2 -m "Phase 2 complete: Library browsing, detail pages, search, image caching"
```

---

## Summary

Phase 2 delivers:
- **14 tasks** with TDD for all data layer code
- **MediaItem** universal model parsing all Emby item types
- **Image URL builder** with size-appropriate thumbnails, posters, and backdrops
- **Reusable widgets**: EmbyImage (cached), MediaCard (poster + progress), MediaGrid (infinite scroll), MediaRow (horizontal), ShimmerGrid (loading)
- **HomeScreen** with Continue Watching, Next Up, Recently Added rows
- **LibraryScreen** with type filter chips (Movies/Shows/Music/Collections), sort menu, paginated infinite-scroll grid
- **MovieDetailScreen** with backdrop header, metadata, genres, overview, similar items
- **SeriesDetailScreen** with season tabs, episode list with thumbnails and progress
- **SearchScreen** with debounced server-side search
- **Bottom navigation** (Home, Library, Search, Settings) via GoRouter StatefulShellRoute
- **Detail routing** that auto-detects item type (movie vs series)
