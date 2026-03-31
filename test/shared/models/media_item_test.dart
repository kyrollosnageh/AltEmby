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
        'RunTimeTicks': 72000000000,
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
