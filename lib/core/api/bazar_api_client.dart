import 'package:dio/dio.dart';

import '../config/api_config.dart';

class BazarApiClient {
  BazarApiClient({
    required ApiConfig config,
    Dio? dio,
    Iterable<Interceptor> interceptors = const [],
  }) : _config = config,
       _dio = dio ?? Dio() {
    _dio.interceptors.addAll(interceptors);
  }

  final ApiConfig _config;
  final Dio _dio;

  String resolveUrl(String path) {
    if (Uri.tryParse(path)?.hasScheme == true) return path;
    final base = Uri.parse(_config.baseUrl);
    return base.resolve(path).toString();
  }

  String endpointUrl(String cmd, String action, {Map<String, dynamic>? query}) {
    final base = Uri.parse(_config.baseUrl);
    return base.replace(
      queryParameters: {'cmd': cmd, 'action': action, ...?query},
    ).toString();
  }

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
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.request<Map<String, dynamic>>(
        _config.baseUrl,
        queryParameters: {'cmd': cmd, 'action': action, ...?query},
        data: body,
        options: Options(
          method: body == null ? 'GET' : 'POST',
          headers: headers,
        ),
      );
    } on DioException catch (error) {
      final payload = error.response?.data;
      final apiError = payload?['error'];
      throw BazarApiException(
        message: apiError is Map
            ? apiError['message']?.toString() ?? 'API request failed'
            : _transportMessage(error),
        details: apiError is Map ? apiError['details'] : null,
        statusCode: error.response?.statusCode,
      );
    }
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

String _transportMessage(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => 'API request timed out',
    DioExceptionType.connectionError => 'Unable to connect to the API',
    _ => 'API request failed',
  };
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
