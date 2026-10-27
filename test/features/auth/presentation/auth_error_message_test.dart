import 'package:bazar/core/error/failures.dart';
import 'package:bazar/features/auth/presentation/auth_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows a failure message rather than the exception type', () {
    expect(
      authErrorMessage(const AuthFailure('লগইন করা যায়নি। আবার চেষ্টা করুন।')),
      'লগইন করা যায়নি। আবার চেষ্টা করুন।',
    );
  });

  test('uses a safe fallback for unexpected login errors', () {
    expect(authErrorMessage(StateError('unexpected')), 'লগইন করা যায়নি। আবার চেষ্টা করুন।');
  });
}
