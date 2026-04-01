// lib/features/player/data/playback_reporter.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';

class PlaybackReporter {
  final EmbyApiClient _apiClient;

  PlaybackReporter({required EmbyApiClient apiClient}) : _apiClient = apiClient;

  Future<void> reportPlaybackStart({
    required String itemId,
    String? mediaSourceId,
    int positionTicks = 0,
    bool isPaused = false,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.playbackStart,
        data: {
          'ItemId': itemId,
          if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
          'PositionTicks': positionTicks,
          'PlayMethod': 'DirectPlay',
          'CanSeek': true,
          'IsPaused': isPaused,
          'IsMuted': false,
        },
      );
    } catch (_) {}
  }

  Future<void> reportPlaybackProgress({
    required String itemId,
    required int positionTicks,
    bool isPaused = false,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.playbackProgress,
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
          'IsPaused': isPaused,
          'IsMuted': false,
          'PlayMethod': 'DirectPlay',
          'CanSeek': true,
        },
      );
    } catch (_) {}
  }

  Future<void> reportPlaybackStopped({
    required String itemId,
    required int positionTicks,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.playbackStopped,
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
        },
      );
    } catch (_) {}
  }

  static int durationToTicks(Duration duration) {
    return duration.inMicroseconds * 10;
  }

  static Duration ticksToDuration(int ticks) {
    return Duration(microseconds: ticks ~/ 10);
  }
}
