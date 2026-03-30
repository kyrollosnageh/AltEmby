// test/widget/user_select_screen_test.dart

import 'package:altemby/features/auth/presentation/user_select_screen.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('UserSelectScreen', () {
    testWidgets('shows "Add Account" button', (tester) async {
      final mockStorage = MockSecureStorageService();
      when(() => mockStorage.loadSavedSessions()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(home: UserSelectScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('shows saved user profiles', (tester) async {
      final mockStorage = MockSecureStorageService();
      when(() => mockStorage.loadSavedSessions()).thenAnswer((_) async => [
            UserSession(
              userId: 'u1',
              userName: 'Alice',
              accessToken: 't1',
              serverId: 's1',
              serverUrl: 'https://emby.test',
            ),
            UserSession(
              userId: 'u2',
              userName: 'Bob',
              accessToken: 't2',
              serverId: 's1',
              serverUrl: 'https://emby.test',
            ),
          ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(home: UserSelectScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
