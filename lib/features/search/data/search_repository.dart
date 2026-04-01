import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

class SearchRepository {
  final EmbyApiClient _apiClient;
  SearchRepository({required EmbyApiClient apiClient}) : _apiClient = apiClient;

  Future<PaginatedResult> search({required String userId, required String query, int limit = 50}) async {
    final data = await _apiClient.get(ApiEndpoints.userItems(userId), queryParameters: {
      'SearchTerm': query, 'Recursive': true,
      'IncludeItemTypes': 'Movie,Series,Episode,Audio,MusicAlbum',
      'Limit': limit, 'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
      'EnableImageTypes': 'Primary', 'ImageTypeLimit': 1,
    });
    return PaginatedResult.fromJson(data as Map<String, dynamic>);
  }
}
