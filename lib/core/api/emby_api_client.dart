// lib/core/api/emby_api_client.dart

import 'package:dio/dio.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/error/app_exceptions.dart';

class EmbyApiClient {
  final Dio _dio;
  final EmbyAuthInterceptor authInterceptor;
  String _baseUrl;

  String get baseUrl => _baseUrl;

  EmbyApiClient({
    required String baseUrl,
    required this.authInterceptor,
    Dio? dio,
  })  : _baseUrl = _normalizeUrl(baseUrl),
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    );
    _dio.interceptors.add(authInterceptor);
  }

  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void updateBaseUrl(String url) {
    _baseUrl = _normalizeUrl(url);
    _dio.options.baseUrl = _baseUrl;
  }

  /// GET request. Returns the response data.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST request. Returns the response data.
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// DELETE request. Returns the response data.
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Build a full URL for media streaming (used by the player).
  /// Appends the auth token as a query parameter since players can't set headers.
  String getStreamUrl(String path, {Map<String, dynamic>? queryParameters}) {
    final params = <String, dynamic>{
      'Static': 'true',
      if (authInterceptor.token != null) 'api_key': authInterceptor.token,
      ...?queryParameters,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_baseUrl$path?$query';
  }

  AppException _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        ServerUnreachableException('Connection timed out: ${e.message}'),
      DioExceptionType.connectionError =>
        ServerUnreachableException('Cannot reach server: ${e.message}'),
      DioExceptionType.badResponse => _mapStatusCode(e.response?.statusCode, e.message),
      _ => NetworkException('Network error: ${e.message}'),
    };
  }

  AppException _mapStatusCode(int? statusCode, String? message) {
    return switch (statusCode) {
      401 => const SessionExpiredException('Session expired. Please log in again.'),
      403 => const AuthenticationException('Access denied.'),
      404 => NetworkException('Not found: $message'),
      _ => NetworkException('Server error ($statusCode): $message'),
    };
  }
}
