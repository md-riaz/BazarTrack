import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key, this.onUserCreated, this.onCancel});

  final VoidCallback? onUserCreated;
  final VoidCallback? onCancel;

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  AdminRole _role = AdminRole.assistant;
  bool _canSeeAllWallets = true;
  bool _canCreateBazar = true;
  bool _canEnterMoney = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .createUser(
            CreateAdminUserRequest(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              role: _role,
            ),
          );
      ref.invalidate(adminUsersProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('নতুন ইউজার যোগ হয়েছে')));
      widget.onUserCreated?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(title: 'Add User'),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _FormCard(
              title: 'ইউজার তথ্য',
              children: [
                _TextInput(
                  controller: _nameController,
                  label: 'নাম',
                  hintText: 'যেমন: Rahim Uddin',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'নাম দিন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _TextInput(
                  controller: _phoneController,
                  label: 'ফোন নম্বর',
                  hintText: '01XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ফোন নম্বর দিন';
                    }
                    return null;
                  },
                ),
              ],
            ),
            _FormCard(
              title: 'রোল নির্বাচন',
              children: [
                for (final role in AdminRole.values)
                  _RoleTile(
                    role: role,
                    selected: role == _role,
                    onTap: () => setState(() => _role = role),
                  ),
              ],
            ),
            _FormCard(
              title: 'পারমিশন',
              children: [
                _PermissionSwitch(
                  title: 'সব ওয়ালেট দেখতে পারবে',
                  value: _canSeeAllWallets,
                  onChanged: (value) =>
                      setState(() => _canSeeAllWallets = value),
                ),
                _PermissionSwitch(
                  title: 'বাজার তৈরি করতে পারবে',
                  value: _canCreateBazar,
                  onChanged: (value) => setState(() => _canCreateBazar = value),
                ),
                _PermissionSwitch(
                  title: 'টাকা এন্ট্রি করতে পারবে',
                  value: _canEnterMoney,
                  onChanged: (value) => setState(() => _canEnterMoney = value),
                ),
              ],
            ),
            PrimaryButton(
              label: _isSaving ? 'সেভ হচ্ছে...' : 'ইউজার যোগ করুন',
              onPressed: _isSaving ? null : _submit,
            ),
            GhostButton(
              label: 'বাতিল',
              onPressed: _isSaving ? null : widget.onCancel,
              foregroundColor: AppColors.text3,
              borderColor: AppColors.border2,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            fillColor: AppColors.surface2,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final AdminRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.text4,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text3,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionSwitch extends StatelessWidget {
  const _PermissionSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
      ),
      activeThumbColor: AppColors.primary,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
