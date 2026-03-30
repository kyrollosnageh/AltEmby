// test/widget/login_screen_test.dart

import 'package:altemby/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows username and password fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows sign in button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows error when username is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username'), findsOneWidget);
    });

    testWidgets('password visibility toggles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      final visibilityIcon = find.byIcon(Icons.visibility_off);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
