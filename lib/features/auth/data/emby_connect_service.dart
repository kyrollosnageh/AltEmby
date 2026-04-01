// lib/features/auth/data/emby_connect_service.dart

import 'package:dio/dio.dart';
import 'package:altemby/core/constants/app_constants.dart';
import 'package:altemby/core/error/app_exceptions.dart';

class ConnectServer {
  final String systemId;
  final String accessKey;
  final String name;
  final String? remoteUrl;
  final String? localUrl;

  const ConnectServer({
    required this.systemId,
    required this.accessKey,
    required this.name,
    this.remoteUrl,
    this.localUrl,
  });

  /// Best URL to use (prefer local, fall back to remote)
  String get url => localUrl ?? remoteUrl ?? '';

  factory ConnectServer.fromJson(Map<String, dynamic> json) => ConnectServer(
        systemId: json['SystemId'] as String? ?? '',
        accessKey: json['AccessKey'] as String? ?? '',
        name: json['Name'] as String? ?? 'Emby Server',
        remoteUrl: json['Url'] as String?,
        localUrl: json['LocalAddress'] as String?,
      );
}

class ConnectUser {
  final String id;
  final String name;
  final String accessToken;

  const ConnectUser({
    required this.id,
    required this.name,
    required this.accessToken,
  });
}

class ConnectExchangeResult {
  final String localUserId;
  final String accessToken;

  const ConnectExchangeResult({
    required this.localUserId,
    required this.accessToken,
  });
}

class EmbyConnectService {
  static const _baseUrl = 'https://connect.emby.media';
  final Dio _dio;

  EmbyConnectService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'X-Application':
                '${AppConstants.appName}/${AppConstants.appVersion}',
            'Content-Type': 'application/json',
          },
        ));

  /// Authenticate with Emby Connect using email/username and password.
  Future<ConnectUser> authenticate({
    required String nameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/service/user/authenticate', data: {
        'nameOrEmail': nameOrEmail,
        'rawpw': password,
      });
      final data = response.data as Map<String, dynamic>;
      final user = data['User'] as Map<String, dynamic>;
      return ConnectUser(
        id: user['Id'] as String,
        name: user['Name'] as String? ?? nameOrEmail,
        accessToken: data['AccessToken'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthenticationException('Invalid Emby Connect credentials',
            userMessage: 'Invalid email or password.');
      }
      throw const NetworkException('Could not reach Emby Connect',
          userMessage:
              'Could not connect to Emby Connect. Check your internet connection.');
    }
  }

  /// Discover servers linked to the Emby Connect account.
  Future<List<ConnectServer>> getServers({
    required String connectUserId,
    required String connectAccessToken,
  }) async {
    try {
      final response = await _dio.get(
        '/service/servers',
        queryParameters: {'userId': connectUserId},
        options: Options(headers: {'X-Connect-UserToken': connectAccessToken}),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ConnectServer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      throw const NetworkException('Failed to fetch servers',
          userMessage: 'Could not retrieve your server list.');
    }
  }

  /// Exchange the Emby Connect access key for a local server token.
  /// This call goes to the Emby server, NOT connect.emby.media.
  Future<ConnectExchangeResult> exchangeToken({
    required String serverUrl,
    required String connectUserId,
    required String accessKey,
    required String deviceId,
    required String deviceName,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    try {
      final response = await dio.get(
        '$serverUrl/emby/Connect/Exchange',
        queryParameters: {
          'format': 'json',
          'ConnectUserId': connectUserId,
        },
        options: Options(headers: {
          'X-MediaBrowser-Token': accessKey,
          'X-Emby-Authorization':
              'MediaBrowser Client="${AppConstants.appName}", Device="$deviceName", DeviceId="$deviceId", Version="${AppConstants.appVersion}"',
        }),
      );
      final data = response.data as Map<String, dynamic>;
      return ConnectExchangeResult(
        localUserId: data['LocalUserId'] as String,
        accessToken: data['AccessToken'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthenticationException(
            'Server rejected Connect token',
            userMessage:
                'This server did not accept your Emby Connect account.');
      }
      throw NetworkException('Could not connect to server: ${e.message}',
          userMessage: 'Could not reach the server to exchange credentials.');
    }
  }
}
