// test/features/auth/presentation/auth_providers_test.dart

import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthNotifier', () {
    late MockSecureStorageService mockStorage;
    late MockAuthRepository mockRepo;
    late AuthNotifier notifier;

    setUp(() {
      mockStorage = MockSecureStorageService();
      mockRepo = MockAuthRepository();
      notifier = AuthNotifier(
        storageService: mockStorage,
        authRepository: mockRepo,
      );
    });

    test('initial state is unauthenticated', () {
      expect(notifier.state, const AuthState.unauthenticated());
    });

    test('tryRestoreSession sets authenticated on stored session', () async {
      final session = UserSession(
        userId: 'u1',
        userName: 'Test',
        accessToken: 'tok',
        serverId: 's1',
        serverUrl: 'https://emby.test',
      );
      when(() => mockStorage.loadSession()).thenAnswer((_) async => session);
      when(() => mockRepo.restoreSession(session)).thenReturn(null);

      await notifier.tryRestoreSession();

      expect(
        notifier.state,
        AuthState.authenticated(session),
      );
    });

    test('tryRestoreSession stays unauthenticated when no session', () async {
      when(() => mockStorage.loadSession()).thenAnswer((_) async => null);

      await notifier.tryRestoreSession();

      expect(notifier.state, const AuthState.unauthenticated());
    });

    test('login sets authenticated on success', () async {
      final session = UserSession(
        userId: 'u1',
        userName: 'Test',
        accessToken: 'tok',
        serverId: 's1',
        serverUrl: 'https://emby.test',
      );
      when(() => mockRepo.login(
            username: 'admin',
            password: 'pass',
            serverUrl: 'https://emby.test',
          )).thenAnswer((_) async => session);
      when(() => mockStorage.saveSession(session)).thenAnswer((_) async {});
      when(() => mockStorage.addSavedSession(session)).thenAnswer((_) async {});

      await notifier.login(
        username: 'admin',
        password: 'pass',
        serverUrl: 'https://emby.test',
      );

      expect(notifier.state, AuthState.authenticated(session));
    });

    test('logout clears state', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      when(() => mockStorage.clearSession()).thenAnswer((_) async {});

      await notifier.logout();

      expect(notifier.state, const AuthState.unauthenticated());
    });
  });
}
