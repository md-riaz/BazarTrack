import 'package:bazar/core/api/bazar_api_client.dart';
import 'package:bazar/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const timeout = Duration(seconds: 15);

  test('Dio with unset timeouts receives bounded defaults', () {
    final dio = Dio();
    BazarApiClient(config: _config(), dio: dio);

    expect(dio.options.connectTimeout, timeout);
    expect(dio.options.sendTimeout, timeout);
    expect(dio.options.receiveTimeout, timeout);
  });

  test('injected Dio timeout policy is preserved', () {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );
    BazarApiClient(config: _config(), dio: dio);

    expect(dio.options.connectTimeout, const Duration(seconds: 2));
    expect(dio.options.sendTimeout, const Duration(seconds: 3));
    expect(dio.options.receiveTimeout, const Duration(seconds: 4));
  });
}

ApiConfig _config() => ApiConfig(
  environment: AppEnvironment.test,
  enabled: true,
  baseUrl: 'https://api.example.test/index.php',
  defaultFundId: 'fund',
  defaultAccountId: 'account',
  defaultManagerId: 'manager',
  defaultAssistantId: 'assistant',
);
