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
      when(() => mockClient.get('/Users/user-1/Items/Resume', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
            'Items': [{'Id': 'm1', 'Name': 'Movie 1', 'Type': 'Movie', 'RunTimeTicks': 100000000000,
              'ImageTags': {}, 'BackdropImageTags': [],
              'UserData': {'PlaybackPositionTicks': 50000000000, 'Played': false}}],
            'TotalRecordCount': 1,
          });
      final items = await repo.getContinueWatching(userId: 'user-1');
      expect(items.length, 1);
      expect(items.first.hasProgress, true);
    });
  });

  group('getRecentlyAdded', () {
    test('fetches recently added items', () async {
      when(() => mockClient.get('/Users/user-1/Items/Latest', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => [
            {'Id': 'm2', 'Name': 'New Movie', 'Type': 'Movie', 'ImageTags': {}, 'BackdropImageTags': []},
          ]);
      final items = await repo.getRecentlyAdded(userId: 'user-1');
      expect(items.length, 1);
      expect(items.first.name, 'New Movie');
    });
  });

  group('getNextUp', () {
    test('fetches next up episodes', () async {
      when(() => mockClient.get('/Shows/NextUp', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
            'Items': [{'Id': 'ep-2', 'Name': 'Episode 2', 'Type': 'Episode', 'SeriesName': 'Show 1',
              'IndexNumber': 2, 'ParentIndexNumber': 1, 'ImageTags': {}, 'BackdropImageTags': []}],
            'TotalRecordCount': 1,
          });
      final items = await repo.getNextUp(userId: 'user-1');
      expect(items.length, 1);
      expect(items.first.name, 'Episode 2');
    });
  });
}
