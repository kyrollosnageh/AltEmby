// test/core/api/emby_api_client_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbyApiClient', () {
    test('constructs with base URL and interceptor', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-id',
        deviceName: 'Test',
      );
      final client = EmbyApiClient(
        baseUrl: 'https://emby.example.com',
        authInterceptor: interceptor,
      );

      expect(client.baseUrl, 'https://emby.example.com');
    });

    test('normalizes base URL by removing trailing slash', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-id',
        deviceName: 'Test',
      );
      final client = EmbyApiClient(
        baseUrl: 'https://emby.example.com/',
        authInterceptor: interceptor,
      );

      expect(client.baseUrl, 'https://emby.example.com');
    });

    test('updateBaseUrl changes the Dio base URL', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-id',
        deviceName: 'Test',
      );
      final client = EmbyApiClient(
        baseUrl: 'https://old.example.com',
        authInterceptor: interceptor,
      );

      client.updateBaseUrl('https://new.example.com');

      expect(client.baseUrl, 'https://new.example.com');
    });
  });
}
