import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

const kEnableDemoRoleLogin = bool.fromEnvironment(
  'BAZAR_ENABLE_DEMO_ROLE_LOGIN',
  defaultValue: true,
);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await _loginWith(
      phone: _phoneController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _loginWith({
    required String phone,
    required String password,
  }) async {
    final user = await ref
        .read(loginControllerProvider.notifier)
        .login(phone: phone, password: password);

    if (user != null && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<AsyncValue<User?>>(loginControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 32),
              child: const Column(
                children: [
                  Text('🛒', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 10),
                  Text(
                    'সহজ বাজার খাতা',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'অফিসের বাজার হিসাব, সহজে।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 28, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LoginField(
                      label: 'ফোন নম্বর',
                      placeholder: '01XXXXXXXXX',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _LoginField(
                      label: 'পাসওয়ার্ড',
                      placeholder: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'পাসওয়ার্ড ভুলে গেছেন?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: loginState.isLoading
                          ? 'লগইন হচ্ছে...'
                          : 'লগইন করুন →',
                      onPressed: loginState.isLoading ? null : _login,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Demo: যেকোনো কিছু লিখে লগইন করুন',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                    if (kEnableDemoRoleLogin) ...[
                      const SizedBox(height: 16),
                      _DemoRoleButton(
                        label: 'Login as Admin',
                        icon: Icons.admin_panel_settings,
                        enabled: !loginState.isLoading,
                        onTap: () => _loginWith(
                          phone: MockAuthRemoteDataSource.demoAdminPhone,
                          password: MockAuthRemoteDataSource.demoPassword,
                        ),
                      ),
                      _DemoRoleButton(
                        label: 'Login as Owner',
                        icon: Icons.account_balance_wallet,
                        enabled: !loginState.isLoading,
                        onTap: () => _loginWith(
                          phone: MockAuthRemoteDataSource.demoOwnerPhone,
                          password: MockAuthRemoteDataSource.demoPassword,
                        ),
                      ),
                      _DemoRoleButton(
                        label: 'Login as Assistant',
                        icon: Icons.shopping_basket,
                        enabled: !loginState.isLoading,
                        onTap: () => _loginWith(
                          phone: MockAuthRemoteDataSource.demoAssistantPhone,
                          password: MockAuthRemoteDataSource.demoPassword,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoRoleButton extends StatelessWidget {
  const _DemoRoleButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          alignment: Alignment.centerLeft,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primaryBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: AppTextStyles.label),
          ),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyStrong,
            decoration: InputDecoration(
              labelText: label,
              hintText: placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
