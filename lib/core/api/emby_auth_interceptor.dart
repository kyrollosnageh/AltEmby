// lib/core/api/emby_auth_interceptor.dart

import 'package:dio/dio.dart';
import 'package:altemby/core/constants/app_constants.dart';

class EmbyAuthInterceptor extends Interceptor {
  String deviceId;
  final String deviceName;
  String? token;

  EmbyAuthInterceptor({
    required this.deviceId,
    required this.deviceName,
    this.token,
  });

  void clearAuth() {
    token = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final parts = <String>[
      'Client="${AppConstants.appName}"',
      'Device="$deviceName"',
      'DeviceId="$deviceId"',
      'Version="${AppConstants.appVersion}"',
    ];

    if (token != null) {
      parts.add('Token="$token"');
    }

    options.headers['X-Emby-Authorization'] = 'MediaBrowser ${parts.join(', ')}';
    handler.next(options);
  }
}
