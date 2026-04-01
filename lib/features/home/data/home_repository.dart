// lib/features/home/data/home_repository.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

class HomeRepository {
  final EmbyApiClient _apiClient;
  HomeRepository({required EmbyApiClient apiClient}) : _apiClient = apiClient;

  Future<List<MediaItem>> getContinueWatching({required String userId, int limit = 20}) async {
    final data = await _apiClient.get('/Users/$userId/Items/Resume', queryParameters: {
      'Limit': limit, 'Recursive': true, 'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
      'EnableImageTypes': 'Primary,Backdrop,Thumb', 'ImageTypeLimit': 1, 'MediaTypes': 'Video',
    });
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaItem>> getRecentlyAdded({required String userId, int limit = 20}) async {
    final data = await _apiClient.get('/Users/$userId/Items/Latest', queryParameters: {
      'Limit': limit, 'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
      'EnableImageTypes': 'Primary,Backdrop', 'ImageTypeLimit': 1, 'IncludeItemTypes': 'Movie,Episode',
    });
    // /Items/Latest returns a flat list
    final items = data as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaItem>> getNextUp({required String userId, int limit = 20}) async {
    final data = await _apiClient.get('/Shows/NextUp', queryParameters: {
      'UserId': userId, 'Limit': limit, 'Fields': 'Overview,RunTimeTicks,UserData,ImageTags',
      'EnableImageTypes': 'Primary,Backdrop', 'ImageTypeLimit': 1,
    });
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
