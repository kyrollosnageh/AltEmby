// test/features/auth/data/auth_repository_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/error/app_exceptions.dart';
import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

class MockEmbyAuthInterceptor extends Mock implements EmbyAuthInterceptor {}

void main() {
  late MockEmbyApiClient mockClient;
  late MockEmbyAuthInterceptor mockInterceptor;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockEmbyApiClient();
    mockInterceptor = MockEmbyAuthInterceptor();
    when(() => mockClient.authInterceptor).thenReturn(mockInterceptor);
    repo = AuthRepository(apiClient: mockClient);
  });

  group('validateServer', () {
    test('returns ServerInfo on valid response', () async {
      when(() => mockClient.get('/System/Info/Public'))
          .thenAnswer((_) async => {
                'ServerName': 'My Emby',
                'Id': 'server-abc',
                'Version': '4.8.0.0',
              });

      final result = await repo.validateServer('https://emby.test');
      expect(result.serverName, 'My Emby');
      expect(result.serverId, 'server-abc');
      expect(result.version, '4.8.0.0');
      expect(result.url, 'https://emby.test');
    });

    test('throws ServerUnreachableException on failure', () async {
      when(() => mockClient.get('/System/Info/Public'))
          .thenThrow(const ServerUnreachableException('timeout'));

      expect(
        () => repo.validateServer('https://emby.test'),
        throwsA(isA<ServerUnreachableException>()),
      );
    });
  });

  group('login', () {
    test('returns UserSession on success', () async {
      when(() => mockClient.post(
            '/Users/AuthenticateByName',
            data: {'Username': 'admin', 'Pw': 'pass123'},
          )).thenAnswer((_) async => {
            'AccessToken': 'tok-abc',
            'ServerId': 'server-abc',
            'User': {
              'Id': 'user-1',
              'Name': 'admin',
            },
          });
      when(() => mockInterceptor.token = any()).thenReturn(null);

      final result = await repo.login(
        username: 'admin',
        password: 'pass123',
        serverUrl: 'https://emby.test',
      );

      expect(result.userId, 'user-1');
      expect(result.accessToken, 'tok-abc');
      expect(result.userName, 'admin');
      verify(() => mockInterceptor.token = 'tok-abc').called(1);
    });

    test('throws AuthenticationException on 401', () async {
      when(() => mockClient.post(
            '/Users/AuthenticateByName',
            data: {'Username': 'bad', 'Pw': 'wrong'},
          )).thenThrow(
              const AuthenticationException('Invalid username or password'));

      expect(
        () => repo.login(
          username: 'bad',
          password: 'wrong',
          serverUrl: 'https://emby.test',
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });

  group('logout', () {
    test('calls logout endpoint and clears token', () async {
      when(() => mockClient.post('/Sessions/Logout'))
          .thenAnswer((_) async => null);
      when(() => mockInterceptor.clearAuth()).thenReturn(null);

      await repo.logout();

      verify(() => mockClient.post('/Sessions/Logout')).called(1);
      verify(() => mockInterceptor.clearAuth()).called(1);
    });
  });
}
