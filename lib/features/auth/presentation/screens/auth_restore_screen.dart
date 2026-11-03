import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class AuthRestoreScreen extends ConsumerWidget {
  const AuthRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: currentUser.isLoading
                ? const _RestoringSession()
                : _RestoreFailed(
                    onRetry: () => ref.invalidate(currentUserProvider),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RestoringSession extends StatelessWidget {
  const _RestoringSession();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('সেশন যাচাই করা হচ্ছে…', style: AppTextStyles.body),
      ],
    );
  }
}

class _RestoreFailed extends StatelessWidget {
  const _RestoreFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        const Text(
          'সার্ভারে সংযোগ করা যাচ্ছে না',
          style: AppTextStyles.screenTitle,
        ),
        const SizedBox(height: 8),
        const Text(
          'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('আবার চেষ্টা করুন'),
        ),
      ],
    );
  }
}
