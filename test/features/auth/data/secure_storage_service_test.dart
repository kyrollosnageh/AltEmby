import 'dart:convert';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('saveSession', () {
    test('saves session JSON to secure storage', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final session = UserSession(
        userId: 'u1',
        userName: 'TestUser',
        accessToken: 'token123',
        serverId: 's1',
        serverUrl: 'https://emby.test',
      );

      await service.saveSession(session);

      verify(() => mockStorage.write(
            key: 'active_session',
            value: jsonEncode(session.toJson()),
          )).called(1);
    });
  });

  group('loadSession', () {
    test('returns null when no session stored', () async {
      when(() => mockStorage.read(key: 'active_session'))
          .thenAnswer((_) async => null);

      final result = await service.loadSession();
      expect(result, isNull);
    });

    test('returns UserSession when stored', () async {
      final sessionJson = jsonEncode({
        'userId': 'u1',
        'userName': 'TestUser',
        'accessToken': 'token123',
        'serverId': 's1',
        'serverUrl': 'https://emby.test',
      });
      when(() => mockStorage.read(key: 'active_session'))
          .thenAnswer((_) async => sessionJson);

      final result = await service.loadSession();
      expect(result, isNotNull);
      expect(result!.userId, 'u1');
      expect(result.accessToken, 'token123');
    });
  });

  group('clearSession', () {
    test('deletes the active session', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.clearSession();

      verify(() => mockStorage.delete(key: 'active_session')).called(1);
    });
  });

  group('savedSessions', () {
    test('saves and retrieves a list of sessions', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final sessions = [
        UserSession(
          userId: 'u1',
          userName: 'User1',
          accessToken: 't1',
          serverId: 's1',
          serverUrl: 'https://emby.test',
        ),
      ];

      await service.saveSessions(sessions);

      verify(() => mockStorage.write(
            key: 'saved_sessions',
            value: jsonEncode(sessions.map((s) => s.toJson()).toList()),
          )).called(1);
    });

    test('returns empty list when no saved sessions', () async {
      when(() => mockStorage.read(key: 'saved_sessions'))
          .thenAnswer((_) async => null);

      final result = await service.loadSavedSessions();
      expect(result, isEmpty);
    });
  });
}
