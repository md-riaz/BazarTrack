import 'package:bazar/core/api/api_session.dart';
import 'package:bazar/core/api/bearer_auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final values = <String, String>{};

  setUp(() {
    values.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = Map<String, dynamic>.from(call.arguments as Map);
          final key = arguments['key'] as String?;
          return switch (call.method) {
            'read' => values[key],
            'write' => values[key!] = arguments['value'] as String,
            'delete' => values.remove(key),
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('adds stored bearer token to outgoing requests', () async {
    values[ApiSessionStore.tokenKey] = 'opaque-token';
    final dio = Dio();
    final events = ApiSessionEvents();
    dio.interceptors.add(
      BearerAuthInterceptor(
        sessionStore: ApiSessionStore(const FlutterSecureStorage()),
        sessionEvents: events,
      ),
    );
    dio.httpClientAdapter = _RecordingAdapter();

    await dio.get<void>('https://example.test');

    expect(
      (_RecordingAdapter.lastOptions?.headers['Authorization']),
      'Bearer opaque-token',
    );
    await events.dispose();
  });

  test('401 clears session and emits unauthorized event', () async {
    values[ApiSessionStore.tokenKey] = 'opaque-token';
    values[ApiSessionStore.userIdKey] = 'user-1';
    final dio = Dio();
    final events = ApiSessionEvents();
    var unauthorized = false;
    final subscription = events.unauthorized.listen((_) => unauthorized = true);
    dio.interceptors.add(
      BearerAuthInterceptor(
        sessionStore: ApiSessionStore(const FlutterSecureStorage()),
        sessionEvents: events,
      ),
    );
    dio.httpClientAdapter = _UnauthorizedAdapter();

    await expectLater(
      dio.get<void>('https://example.test'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(values, isEmpty);
    expect(unauthorized, isTrue);
    await subscription.cancel();
    await events.dispose();
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  static RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('', 401);
  }

  @override
  void close({bool force = false}) {}
}
