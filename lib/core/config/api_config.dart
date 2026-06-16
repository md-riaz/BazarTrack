import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.fromEnvironment(),
);

class ApiConfig {
  const ApiConfig({
    required this.enabled,
    required this.baseUrl,
    required this.defaultFundId,
    required this.defaultAccountId,
    required this.defaultManagerId,
    required this.defaultAssistantId,
    this.clientId = 'bazartrack-flutter',
  });

  factory ApiConfig.fromEnvironment() {
    final enabled = _boolValue(
      const String.fromEnvironment('BAZAR_API_ENABLED'),
      _env('BAZAR_API_ENABLED'),
    );
    final baseUrl = _stringValue(
      const String.fromEnvironment('BAZAR_API_BASE_URL'),
      _env('BAZAR_API_BASE_URL'),
      'http://127.0.0.1:8080/index.php',
    );
    return ApiConfig(
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

  final bool enabled;
  final String baseUrl;
  final String defaultFundId;
  final String defaultAccountId;
  final String defaultManagerId;
  final String defaultAssistantId;
  final String clientId;
}

String? _env(String key) {
  try {
    return dotenv.maybeGet(key);
  } catch (_) {
    return null;
  }
}

bool _boolValue(String compileTime, String? envValue) {
  final raw = compileTime.isNotEmpty ? compileTime : envValue;
  return raw == 'true' || raw == '1' || raw == 'yes';
}

String _stringValue(String compileTime, String? envValue, String fallback) {
  if (compileTime.isNotEmpty) return compileTime;
  final value = envValue?.trim();
  if (value != null && value.isNotEmpty) return value;
  return fallback;
}
