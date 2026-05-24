import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/app_divider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/settings_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController(text: 'Rahim Uddin');
  final _phoneController = TextEditingController(text: '01711-XXXXXX');
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invalidPassword =
        _newPasswordController.text.isNotEmpty &&
        _newPasswordController.text.length < 8;
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'প্রোফাইল সম্পাদনা',
        leading: BackButton(onPressed: widget.onBack),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const HAvatar(label: 'RU', size: 72),
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ছবি পরিবর্তন করুন',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const AppDivider(height: 4),
          const SectionHeader(title: 'ব্যক্তিগত তথ্য'),
          _Field(label: 'পূর্ণ নাম', controller: _nameController),
          _Field(label: 'ফোন নম্বর', controller: _phoneController),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ভূমিকা (Role)',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 13),
                  ),
                ),
                const HPill(
                  label: 'assistant',
                  backgroundColor: AppColors.positiveLight,
                  foregroundColor: AppColors.positiveDark,
                ),
                const SizedBox(width: 8),
                Text('Admin পরিবর্তন করবেন', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const AppDivider(),
          const SectionHeader(title: 'পাসওয়ার্ড পরিবর্তন'),
          _Field(
            label: 'বর্তমান পাসওয়ার্ড',
            controller: _oldPasswordController,
            obscureText: true,
          ),
          _Field(
            label: 'নতুন পাসওয়ার্ড',
            controller: _newPasswordController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          if (invalidPassword)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.negativeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'পাসওয়ার্ড কমপক্ষে ৮ অক্ষর হতে হবে',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.negativeDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_saved)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.positiveLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'প্রোফাইল সংরক্ষিত হয়েছে',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.positiveDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          PrimaryButton(
            label: 'সংরক্ষণ করুন',
            onPressed: () => setState(() => _saved = true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
