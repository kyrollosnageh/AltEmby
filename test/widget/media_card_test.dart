// test/widget/media_card_test.dart

import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaCard', () {
    final testItem = MediaItem.fromJson({
      'Id': 'test-1',
      'Name': 'Test Movie',
      'Type': 'Movie',
      'ProductionYear': 2023,
      'ImageTags': {'Primary': 'tag-123'},
      'BackdropImageTags': [],
    });

    testWidgets('displays item name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(item: testItem, baseUrl: 'https://emby.test', onTap: () {}),
            ),
          ),
        ),
      );
      expect(find.text('Test Movie'), findsOneWidget);
    });

    testWidgets('displays year when available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(item: testItem, baseUrl: 'https://emby.test', onTap: () {}),
            ),
          ),
        ),
      );
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(item: testItem, baseUrl: 'https://emby.test', onTap: () => tapped = true),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MediaCard));
      expect(tapped, true);
    });

    testWidgets('shows progress bar for in-progress items', (tester) async {
      final inProgressItem = MediaItem.fromJson({
        'Id': 'test-2',
        'Name': 'In Progress',
        'Type': 'Movie',
        'RunTimeTicks': 100000000000,
        'ImageTags': {'Primary': 'tag-123'},
        'BackdropImageTags': [],
        'UserData': {'PlaybackPositionTicks': 50000000000, 'Played': false},
      });
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MediaCard(item: inProgressItem, baseUrl: 'https://emby.test', onTap: () {}),
            ),
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
