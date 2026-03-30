// test/core/api/emby_auth_interceptor_test.dart

import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbyAuthInterceptor', () {
    test('adds X-Emby-Authorization header without token when unauthenticated', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-device-id',
        deviceName: 'TestDevice',
      );

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );

      final header = options.headers['X-Emby-Authorization'] as String;
      expect(header, contains('Client="${AppConstants.appName}"'));
      expect(header, contains('Device="TestDevice"'));
      expect(header, contains('DeviceId="test-device-id"'));
      expect(header, contains('Version="${AppConstants.appVersion}"'));
      expect(header, isNot(contains('Token=')));
    });

    test('adds X-Emby-Authorization header with token when authenticated', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-device-id',
        deviceName: 'TestDevice',
      );
      interceptor.token = 'my-access-token';

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );

      final header = options.headers['X-Emby-Authorization'] as String;
      expect(header, contains('Token="my-access-token"'));
    });

    test('clears token on clearAuth', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-device-id',
        deviceName: 'TestDevice',
      );
      interceptor.token = 'my-access-token';
      interceptor.clearAuth();

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );

      final header = options.headers['X-Emby-Authorization'] as String;
      expect(header, isNot(contains('Token=')));
    });
  });
}
