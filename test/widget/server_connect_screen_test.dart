// test/widget/server_connect_screen_test.dart

import 'package:altemby/features/auth/presentation/server_connect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConnectScreen', () {
    testWidgets('shows text field and connect button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerConnectScreen()),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('shows error when URL is empty and connect pressed',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerConnectScreen()),
        ),
      );

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a server URL'), findsOneWidget);
    });

    testWidgets('shows HTTPS warning for HTTP URLs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerConnectScreen()),
        ),
      );

      await tester.enterText(find.byType(TextField), 'http://192.168.1.100:8096');
      await tester.pumpAndSettle();

      expect(find.textContaining('not using HTTPS'), findsOneWidget);
    });
  });
}
