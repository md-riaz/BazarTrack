import 'package:dio/dio.dart';

import '../config/api_config.dart';

class BazarApiClient {
  BazarApiClient({required ApiConfig config, Dio? dio})
    : _config = config,
      _dio = dio ?? Dio();

  final ApiConfig _config;
  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String cmd,
    String action, {
    Map<String, dynamic>? query,
  }) {
    return _request(cmd, action, query: query, body: null);
  }

  Future<Map<String, dynamic>> post(
    String cmd,
    String action, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _request(
      cmd,
      action,
      body: body ?? const <String, dynamic>{},
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Map<String, dynamic>> _request(
    String cmd,
    String action, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      'X-Client-Id': _config.clientId,
    };
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    final response = await _dio.request<Map<String, dynamic>>(
      _config.baseUrl,
      queryParameters: {'cmd': cmd, 'action': action, ...?query},
      data: body,
      options: Options(method: body == null ? 'GET' : 'POST', headers: headers),
    );
    final payload = response.data;
    if (payload == null) return const <String, dynamic>{};
    if (payload['error'] case final Map<String, dynamic> error) {
      throw BazarApiException(
        message: error['message']?.toString() ?? 'API request failed',
        details: error['details'],
        statusCode: response.statusCode,
      );
    }
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is List) return {'items': data};
    return {'value': data};
  }
}

class BazarApiException implements Exception {
  const BazarApiException({
    this.statusCode,
    required this.message,
    this.details,
  });

  final int? statusCode;
  final String message;
  final Object? details;

  @override
  String toString() => 'BazarApiException($statusCode): $message';
}
