import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../auth_error_message.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final changed = await ref.read(loginControllerProvider.notifier).changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (changed && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    ref.listen(loginControllerProvider, (_, next) {
      next.whenOrNull(error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authErrorMessage(error))),
          );
        }
      });
    });
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('পাসওয়ার্ড পরিবর্তন'), automaticallyImplyLeading: false),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('নিরাপত্তার জন্য অস্থায়ী পাসওয়ার্ড পরিবর্তন করুন।'),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('current-password'),
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'বর্তমান পাসওয়ার্ড'),
                validator: (value) => value == null || value.isEmpty ? 'বর্তমান পাসওয়ার্ড দিন' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('new-password'),
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড'),
                validator: (value) => value == null || value.length < 10 ? 'কমপক্ষে ১০ অক্ষর দিন' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('confirm-password'),
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'নতুন পাসওয়ার্ড আবার দিন'),
                validator: (value) => value != _newController.text ? 'পাসওয়ার্ড মিলছে না' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.isLoading ? null : _submit,
                child: Text(state.isLoading ? 'পরিবর্তন হচ্ছে...' : 'পাসওয়ার্ড পরিবর্তন করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
