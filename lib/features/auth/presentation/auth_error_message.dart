import '../../../core/error/failures.dart';

const _fallbackLoginError = 'লগইন করা যায়নি। আবার চেষ্টা করুন।';

String authErrorMessage(Object error) => switch (error) {
  Failure(:final message) => message,
  _ => _fallbackLoginError,
};
