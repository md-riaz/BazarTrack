import 'package:bazar/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release mode always resolves to production', () {
    expect(
      resolveAppEnvironment(isReleaseMode: true, assetValue: 'development'),
      AppEnvironment.production,
    );
    expect(
      resolveAppEnvironment(
        isReleaseMode: true,
        compileTime: 'production',
        assetValue: 'development',
      ),
      AppEnvironment.production,
    );
  });

  test('release mode rejects a non-production compile-time override', () {
    expect(
      () => resolveAppEnvironment(
        isReleaseMode: true,
        compileTime: 'development',
        assetValue: 'development',
      ),
      throwsStateError,
    );
    expect(
      () => resolveAppEnvironment(isReleaseMode: true, compileTime: 'test'),
      throwsStateError,
    );
  });

  test('debug mode accepts development and test environments', () {
    expect(
      resolveAppEnvironment(
        isReleaseMode: false,
        compileTime: 'test',
        assetValue: 'development',
      ),
      AppEnvironment.test,
    );
    expect(
      resolveAppEnvironment(isReleaseMode: false, assetValue: 'development'),
      AppEnvironment.development,
    );
  });

  test('accepts development API configuration with demo defaults', () {
    final config = ApiConfig(
      environment: AppEnvironment.development,
      enabled: true,
      baseUrl: 'http://127.0.0.1:8080/index.php',
      defaultFundId: 'fund1',
      defaultAccountId: 'acc1',
      defaultManagerId: 'manager1',
      defaultAssistantId: 'assistant1',
    );

    expect(config.isProduction, isFalse);
  });

  test('production requires an enabled HTTPS API', () {
    expect(
      () => ApiConfig(
        environment: AppEnvironment.production,
        enabled: true,
        baseUrl: 'http://api.example.com/index.php',
        defaultFundId: 'prod-fund',
        defaultAccountId: 'prod-account',
        defaultManagerId: 'prod-manager',
        defaultAssistantId: 'prod-assistant',
      ),
      throwsStateError,
    );
  });

  test('production rejects local URLs and demo IDs', () {
    expect(
      () => ApiConfig(
        environment: AppEnvironment.production,
        enabled: true,
        baseUrl: 'https://127.0.0.1/index.php',
        defaultFundId: 'prod-fund',
        defaultAccountId: 'prod-account',
        defaultManagerId: 'prod-manager',
        defaultAssistantId: 'prod-assistant',
      ),
      throwsStateError,
    );
    expect(
      () => ApiConfig(
        environment: AppEnvironment.production,
        enabled: true,
        baseUrl: 'https://api.example.com/index.php',
        defaultFundId: 'fund1',
        defaultAccountId: 'prod-account',
        defaultManagerId: 'prod-manager',
        defaultAssistantId: 'prod-assistant',
      ),
      throwsStateError,
    );
  });

  test('accepts explicit production values', () {
    final config = ApiConfig(
      environment: AppEnvironment.production,
      enabled: true,
      baseUrl: 'https://api.example.com/index.php',
      defaultFundId: 'prod-fund',
      defaultAccountId: 'prod-account',
      defaultManagerId: 'prod-manager',
      defaultAssistantId: 'prod-assistant',
    );

    expect(config.isProduction, isTrue);
  });
}
