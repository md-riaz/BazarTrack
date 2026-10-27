import 'package:dio/dio.dart';

import 'api_session.dart';

class BearerAuthInterceptor extends Interceptor {
  BearerAuthInterceptor({
    required ApiSessionStore sessionStore,
    required ApiSessionEvents sessionEvents,
  }) : _sessionStore = sessionStore,
       _sessionEvents = sessionEvents;

  final ApiSessionStore _sessionStore;
  final ApiSessionEvents _sessionEvents;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _sessionStore.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _sessionStore.clear();
      _sessionEvents.notifyUnauthorized();
    }
    handler.next(err);
  }
}
