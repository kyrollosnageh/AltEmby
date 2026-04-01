// lib/core/api/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  // Server info (no auth required)
  static const String publicSystemInfo = '/System/Info/Public';

  // Authentication
  static const String authenticateByName = '/Users/AuthenticateByName';
  static const String logout = '/Sessions/Logout';

  // Users
  static const String publicUsers = '/Users/Public';

  // Library (user-scoped)
  static String userItems(String userId) => '/Users/$userId/Items';
  static String userItem(String userId, String itemId) =>
      '/Users/$userId/Items/$itemId';

  // Images
  static String itemImage(String itemId, String type, {int? index}) {
    if (index != null) return '/Items/$itemId/Images/$type/$index';
    return '/Items/$itemId/Images/$type';
  }

  // Playback
  static String videoStream(String itemId) => '/Videos/$itemId/stream';
  static String audioStream(String itemId) => '/Audio/$itemId/stream';
  static String fileDownload(String itemId) => '/Items/$itemId/File';

  // Session reporting
  static const String playbackStart = '/Sessions/Playing';
  static const String playbackProgress = '/Sessions/Playing/Progress';
  static const String playbackStopped = '/Sessions/Playing/Stopped';

  // TV Shows
  static String showSeasons(String seriesId) => '/Shows/$seriesId/Seasons';
  static String showEpisodes(String seriesId) => '/Shows/$seriesId/Episodes';
}
