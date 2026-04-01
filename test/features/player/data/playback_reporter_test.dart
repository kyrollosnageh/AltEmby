// test/features/player/data/playback_reporter_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/player/data/playback_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

void main() {
  late MockEmbyApiClient mockClient;
  late PlaybackReporter reporter;

  setUp(() {
    mockClient = MockEmbyApiClient();
    reporter = PlaybackReporter(apiClient: mockClient);
  });

  group('reportPlaybackStart', () {
    test('sends correct payload to /Sessions/Playing', () async {
      when(() => mockClient.post('/Sessions/Playing', data: any(named: 'data')))
          .thenAnswer((_) async => null);

      await reporter.reportPlaybackStart(
        itemId: 'item-1',
        mediaSourceId: 'src-1',
        positionTicks: 0,
        isPaused: false,
      );

      verify(() => mockClient.post('/Sessions/Playing', data: {
            'ItemId': 'item-1',
            'MediaSourceId': 'src-1',
            'PositionTicks': 0,
            'PlayMethod': 'DirectPlay',
            'CanSeek': true,
            'IsPaused': false,
            'IsMuted': false,
          })).called(1);
    });
  });

  group('reportPlaybackProgress', () {
    test('sends correct payload to /Sessions/Playing/Progress', () async {
      when(() => mockClient.post('/Sessions/Playing/Progress', data: any(named: 'data')))
          .thenAnswer((_) async => null);

      await reporter.reportPlaybackProgress(
        itemId: 'item-1',
        positionTicks: 300000000000,
        isPaused: false,
      );

      verify(() => mockClient.post('/Sessions/Playing/Progress', data: {
            'ItemId': 'item-1',
            'PositionTicks': 300000000000,
            'IsPaused': false,
            'IsMuted': false,
            'PlayMethod': 'DirectPlay',
            'CanSeek': true,
          })).called(1);
    });
  });

  group('reportPlaybackStopped', () {
    test('sends correct payload to /Sessions/Playing/Stopped', () async {
      when(() => mockClient.post('/Sessions/Playing/Stopped', data: any(named: 'data')))
          .thenAnswer((_) async => null);

      await reporter.reportPlaybackStopped(
        itemId: 'item-1',
        positionTicks: 500000000000,
      );

      verify(() => mockClient.post('/Sessions/Playing/Stopped', data: {
            'ItemId': 'item-1',
            'PositionTicks': 500000000000,
          })).called(1);
    });
  });

  group('durationToTicks', () {
    test('converts Duration to Emby ticks correctly', () {
      final ticks = PlaybackReporter.durationToTicks(const Duration(seconds: 5));
      expect(ticks, 50000000); // 5 seconds * 10,000,000
    });
  });

  group('ticksToDuration', () {
    test('converts Emby ticks to Duration correctly', () {
      final duration = PlaybackReporter.ticksToDuration(50000000);
      expect(duration.inSeconds, 5);
    });
  });
}
