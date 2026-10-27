import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.fromEnvironment(),
);

enum AppEnvironment { development, test, production }

class ApiConfig {
  ApiConfig({
    required this.environment,
    required this.enabled,
    required this.baseUrl,
    required this.defaultFundId,
    required this.defaultAccountId,
    required this.defaultManagerId,
    required this.defaultAssistantId,
    this.clientId = 'bazartrack-flutter',
  }) {
    _validate();
  }

  factory ApiConfig.fromEnvironment() {
    final environment = resolveAppEnvironment(
      isReleaseMode: kReleaseMode,
      compileTime: const String.fromEnvironment('BAZAR_APP_ENV'),
      assetValue: _env('BAZAR_APP_ENV'),
    );
    final enabled = _boolValue(
      const String.fromEnvironment('BAZAR_API_ENABLED'),
      _env('BAZAR_API_ENABLED'),
      fallback: false,
    );
    final baseUrl = _stringValue(
      const String.fromEnvironment('BAZAR_API_BASE_URL'),
      _env('BAZAR_API_BASE_URL'),
      'http://127.0.0.1:8080/index.php',
    );
    return ApiConfig(
      environment: environment,
      enabled: enabled,
      baseUrl: baseUrl,
      defaultFundId: _stringValue(
        const String.fromEnvironment('BAZAR_DEFAULT_FUND_ID'),
        _env('BAZAR_DEFAULT_FUND_ID'),
        'fund1',
      ),
      defaultAccountId: _stringValue(
        const String.fromEnvironment('BAZAR_DEFAULT_ACCOUNT_ID'),
        _env('BAZAR_DEFAULT_ACCOUNT_ID'),
        'acc1',
      ),
      defaultManagerId: _stringValue(
        const String.fromEnvironment('BAZAR_DEFAULT_MANAGER_ID'),
        _env('BAZAR_DEFAULT_MANAGER_ID'),
        'manager1',
      ),
      defaultAssistantId: _stringValue(
        const String.fromEnvironment('BAZAR_DEFAULT_ASSISTANT_ID'),
        _env('BAZAR_DEFAULT_ASSISTANT_ID'),
        'assistant1',
      ),
      clientId: _stringValue(
        const String.fromEnvironment('BAZAR_API_CLIENT_ID'),
        _env('BAZAR_API_CLIENT_ID'),
        'bazartrack-flutter',
      ),
    );
  }

  final AppEnvironment environment;
  final bool enabled;
  final String baseUrl;
  final String defaultFundId;
  final String defaultAccountId;
  final String defaultManagerId;
  final String defaultAssistantId;
  final String clientId;

  bool get isProduction => environment == AppEnvironment.production;

  void _validate() {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('BAZAR_API_BASE_URL must be an absolute URL.');
    }
    if (!isProduction) return;
    if (!enabled) {
      throw StateError('The API cannot be disabled in production.');
    }
    if (uri.scheme != 'https') {
      throw StateError('Production API requests require HTTPS.');
    }
    if (_isLocalHost(uri.host)) {
      throw StateError('Production API URL cannot target localhost.');
    }
    const demoIds = {'fund1', 'acc1', 'manager1', 'assistant1'};
    if (demoIds.contains(defaultFundId) ||
        demoIds.contains(defaultAccountId) ||
        demoIds.contains(defaultManagerId) ||
        demoIds.contains(defaultAssistantId)) {
      throw StateError('Production configuration cannot use demo IDs.');
    }
  }
}

String? _env(String key) {
  try {
    return dotenv.maybeGet(key);
  } catch (_) {
    return null;
  }
}

@visibleForTesting
AppEnvironment resolveAppEnvironment({
  required bool isReleaseMode,
  String compileTime = '',
  String? assetValue,
}) {
  final explicit = compileTime.trim().toLowerCase();
  if (isReleaseMode) {
    if (explicit.isNotEmpty && explicit != 'production' && explicit != 'prod') {
      throw StateError('Release builds require BAZAR_APP_ENV=production.');
    }
    return AppEnvironment.production;
  }
  final value = explicit.isNotEmpty
      ? explicit
      : assetValue?.trim().toLowerCase();
  return switch (value) {
    'production' || 'prod' => AppEnvironment.production,
    'test' => AppEnvironment.test,
    'development' || 'dev' => AppEnvironment.development,
    null || '' => AppEnvironment.development,
    _ => throw StateError('Unsupported BAZAR_APP_ENV: $value'),
  };
}

bool _boolValue(
  String compileTime,
  String? envValue, {
  required bool fallback,
}) {
  final raw = (compileTime.isNotEmpty ? compileTime : envValue)
      ?.trim()
      .toLowerCase();
  if (raw == null || raw.isEmpty) return fallback;
  if (raw == 'true' || raw == '1' || raw == 'yes') return true;
  if (raw == 'false' || raw == '0' || raw == 'no') return false;
  throw StateError('Expected a boolean configuration value, got: $raw');
}

String _stringValue(String compileTime, String? envValue, String fallback) {
  if (compileTime.isNotEmpty) return compileTime;
  final value = envValue?.trim();
  if (value != null && value.isNotEmpty) return value;
  return fallback;
}

bool _isLocalHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1' ||
      normalized == '10.0.2.2';
}
