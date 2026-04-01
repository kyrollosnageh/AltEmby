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
      when(() => mockClient.get('/Users/user-1/Items', queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
            'Items': [{'Id': 'm1', 'Name': 'Inception', 'Type': 'Movie', 'ImageTags': {}, 'BackdropImageTags': []}],
            'TotalRecordCount': 1, 'StartIndex': 0,
          });

      final result = await repo.search(userId: 'user-1', query: 'Inception');
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Inception');

      verify(() => mockClient.get('/Users/user-1/Items', queryParameters: {
        'SearchTerm': 'Inception', 'Recursive': true,
        'IncludeItemTypes': 'Movie,Series,Episode,Audio,MusicAlbum',
        'Limit': 50, 'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
        'EnableImageTypes': 'Primary', 'ImageTypeLimit': 1,
      })).called(1);
    });
  });
}
