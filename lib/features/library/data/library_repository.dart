// lib/features/library/data/library_repository.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

class LibraryRepository {
  final EmbyApiClient _apiClient;
  LibraryRepository({required EmbyApiClient apiClient}) : _apiClient = apiClient;

  static const _defaultFields = 'Overview,Genres,RunTimeTicks,UserData,ImageTags';

  Future<PaginatedResult> getItems({
    required String userId, String? includeTypes, int startIndex = 0, int limit = 50,
    String sortBy = 'SortName', String sortOrder = 'Ascending',
    String? parentId, String? genres, String? years, bool? isPlayed, String? searchTerm,
  }) async {
    final params = <String, dynamic>{
      if (includeTypes != null) 'IncludeItemTypes': includeTypes,
      'Recursive': true, 'StartIndex': startIndex, 'Limit': limit,
      'Fields': _defaultFields, 'SortBy': sortBy, 'SortOrder': sortOrder,
      'EnableImageTypes': 'Primary,Backdrop,Thumb', 'ImageTypeLimit': 1,
      if (parentId != null) 'ParentId': parentId,
      if (genres != null) 'Genres': genres,
      if (years != null) 'Years': years,
      if (isPlayed != null) 'IsPlayed': isPlayed,
      if (searchTerm != null) 'SearchTerm': searchTerm,
    };
    final data = await _apiClient.get(ApiEndpoints.userItems(userId), queryParameters: params);
    return PaginatedResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<MediaItem>> getUserViews({required String userId}) async {
    final data = await _apiClient.get('/Users/$userId/Views');
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaItem>> getSeasons({required String seriesId, required String userId}) async {
    final data = await _apiClient.get(ApiEndpoints.showSeasons(seriesId), queryParameters: {
      'UserId': userId, 'Fields': _defaultFields, 'EnableImageTypes': 'Primary', 'ImageTypeLimit': 1,
    });
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaItem>> getEpisodes({required String seriesId, required String userId, String? seasonId}) async {
    final data = await _apiClient.get(ApiEndpoints.showEpisodes(seriesId), queryParameters: {
      'UserId': userId, 'Fields': _defaultFields, 'EnableImageTypes': 'Primary,Backdrop', 'ImageTypeLimit': 1,
      if (seasonId != null) 'SeasonId': seasonId,
    });
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MediaItem> getItemDetails({required String itemId, required String userId}) async {
    final data = await _apiClient.get(ApiEndpoints.userItem(userId, itemId), queryParameters: {
      'Fields': 'Overview,Genres,Studios,People,RunTimeTicks,UserData,ImageTags,MediaSources,Chapters,ExternalUrls,ProviderIds',
    });
    return MediaItem.fromJson(data as Map<String, dynamic>);
  }

  Future<List<MediaItem>> getSimilarItems({required String itemId, int limit = 12}) async {
    final data = await _apiClient.get('/Items/$itemId/Similar', queryParameters: {
      'Limit': limit, 'Fields': 'Overview,UserData,ImageTags', 'EnableImageTypes': 'Primary', 'ImageTypeLimit': 1,
    });
    final items = (data as Map<String, dynamic>)['Items'] as List<dynamic>;
    return items.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
