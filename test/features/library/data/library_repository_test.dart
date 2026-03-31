// test/features/library/data/library_repository_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/library/data/library_repository.dart';
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
      when(() => mockClient.get('/Users/user-1/Items', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
            'Items': [{'Id': 'm1', 'Name': 'Movie 1', 'Type': 'Movie', 'ImageTags': {}, 'BackdropImageTags': []}],
            'TotalRecordCount': 100, 'StartIndex': 0,
          });

      final result = await repo.getItems(userId: 'user-1', includeTypes: 'Movie', startIndex: 0, limit: 50);
      expect(result.items.length, 1);
      expect(result.totalCount, 100);
      expect(result.items.first.name, 'Movie 1');

      verify(() => mockClient.get('/Users/user-1/Items', queryParameters: {
        'IncludeItemTypes': 'Movie', 'Recursive': true, 'StartIndex': 0, 'Limit': 50,
        'Fields': 'Overview,Genres,RunTimeTicks,UserData,ImageTags',
        'SortBy': 'SortName', 'SortOrder': 'Ascending',
        'EnableImageTypes': 'Primary,Backdrop,Thumb', 'ImageTypeLimit': 1,
      })).called(1);
    });

    test('applies sorting and filtering', () async {
      when(() => mockClient.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {'Items': [], 'TotalRecordCount': 0, 'StartIndex': 0});

      await repo.getItems(userId: 'user-1', includeTypes: 'Movie',
        sortBy: 'DateCreated', sortOrder: 'Descending', genres: 'Action', isPlayed: false);

      verify(() => mockClient.get('/Users/user-1/Items', queryParameters: {
        'IncludeItemTypes': 'Movie', 'Recursive': true, 'StartIndex': 0, 'Limit': 50,
        'Fields': 'Overview,Genres,RunTimeTicks,UserData,ImageTags',
        'SortBy': 'DateCreated', 'SortOrder': 'Descending',
        'EnableImageTypes': 'Primary,Backdrop,Thumb', 'ImageTypeLimit': 1,
        'Genres': 'Action', 'IsPlayed': false,
      })).called(1);
    });
  });

  group('getUserViews', () {
    test('fetches library root folders', () async {
      when(() => mockClient.get('/Users/user-1/Views')).thenAnswer((_) async => {
        'Items': [
          {'Id': 'lib-1', 'Name': 'Movies', 'Type': 'CollectionFolder', 'CollectionType': 'movies', 'ImageTags': {}, 'BackdropImageTags': []},
          {'Id': 'lib-2', 'Name': 'TV Shows', 'Type': 'CollectionFolder', 'CollectionType': 'tvshows', 'ImageTags': {}, 'BackdropImageTags': []},
        ],
        'TotalRecordCount': 2,
      });
      final views = await repo.getUserViews(userId: 'user-1');
      expect(views.length, 2);
      expect(views[0].name, 'Movies');
    });
  });

  group('getSeasons', () {
    test('fetches seasons for a series', () async {
      when(() => mockClient.get('/Shows/series-1/Seasons', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
            'Items': [{'Id': 'season-1', 'Name': 'Season 1', 'Type': 'Season', 'IndexNumber': 1, 'ImageTags': {}, 'BackdropImageTags': []}],
            'TotalRecordCount': 1,
          });
      final seasons = await repo.getSeasons(seriesId: 'series-1', userId: 'user-1');
      expect(seasons.length, 1);
      expect(seasons.first.name, 'Season 1');
    });
  });

  group('getEpisodes', () {
    test('fetches episodes for a series and season', () async {
      when(() => mockClient.get('/Shows/series-1/Episodes', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
            'Items': [{'Id': 'ep-1', 'Name': 'Pilot', 'Type': 'Episode', 'IndexNumber': 1, 'ParentIndexNumber': 1, 'ImageTags': {}, 'BackdropImageTags': []}],
            'TotalRecordCount': 1,
          });
      final episodes = await repo.getEpisodes(seriesId: 'series-1', seasonId: 'season-1', userId: 'user-1');
      expect(episodes.length, 1);
      expect(episodes.first.name, 'Pilot');
    });
  });
}
