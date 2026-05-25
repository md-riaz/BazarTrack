import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({
    super.key,
    this.walletId,
    this.onWalletCreated,
    this.onCancel,
  });

  final String? walletId;
  final VoidCallback? onWalletCreated;
  final VoidCallback? onCancel;

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedOwnerIds = <String>{};
  String _type = adminWalletTypes.first;
  bool _isSaving = false;
  bool _didPrefill = false;

  bool get _isEditing => widget.walletId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedOwnerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমপক্ষে একজন মালিক নির্বাচন করুন')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final ownerIds = _selectedOwnerIds.toList(growable: false);
      if (_isEditing) {
        await ref
            .read(adminRepositoryProvider)
            .updateWallet(
              UpdateAdminWalletRequest(
                id: widget.walletId!,
                name: _nameController.text.trim(),
                type: _type,
                ownerIds: ownerIds,
              ),
            );
      } else {
        await ref
            .read(adminRepositoryProvider)
            .createWallet(
              CreateAdminWalletRequest(
                name: _nameController.text.trim(),
                type: _type,
                ownerIds: ownerIds,
              ),
            );
      }
      ref.invalidate(adminWalletsProvider);
      if (!mounted) {
        return;
      }
      final message = _isEditing
          ? 'ওয়ালেট আপডেট হয়েছে'
          : 'নতুন ওয়ালেট যোগ হয়েছে';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      widget.onWalletCreated?.call();
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
    final users = ref.watch(adminUsersProvider);
    final wallets = ref.watch(adminWalletsProvider);
    if (_isEditing && !_didPrefill) {
      wallets.whenData((items) {
        AdminWallet? wallet;
        for (final item in items) {
          if (item.id == widget.walletId) {
            wallet = item;
            break;
          }
        }
        if (wallet == null) {
          return;
        }
        _nameController.text = wallet.name;
        _type = wallet.type;
        _selectedOwnerIds
          ..clear()
          ..addAll(wallet.ownerIds);
        _didPrefill = true;
      });
    }
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(title: _isEditing ? 'ওয়ালেট এডিট' : 'নতুন ওয়ালেট'),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _FormCard(
              title: 'ওয়ালেট তথ্য',
              children: [
                _TextInput(
                  controller: _nameController,
                  label: 'ওয়ালেটের নাম',
                  hintText: 'যেমন: Office Wallet',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ওয়ালেটের নাম দিন';
                    }
                    return null;
                  },
                ),
              ],
            ),
            _FormCard(
              title: 'ধরন নির্বাচন',
              children: [
                for (final type in adminWalletTypes)
                  _TypeTile(
                    type: type,
                    selected: type == _type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
            _FormCard(
              title: 'মালিক নির্বাচন',
              children: [
                users.when(
                  data: (items) {
                    final owners = items
                        .where(
                          (user) =>
                              user.isActive && user.role == AdminRole.owner,
                        )
                        .toList(growable: false);
                    if (owners.isEmpty) {
                      return Text(
                        'কোনো সক্রিয় মালিক নেই',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.text3,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final owner in owners)
                          _OwnerTile(
                            owner: owner,
                            selected: _selectedOwnerIds.contains(owner.id),
                            onTap: () => setState(() {
                              if (_selectedOwnerIds.contains(owner.id)) {
                                _selectedOwnerIds.remove(owner.id);
                              } else {
                                _selectedOwnerIds.add(owner.id);
                              }
                            }),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Text(
                    'মালিক লোড করা যায়নি',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.negative,
                    ),
                  ),
                ),
              ],
            ),
            PrimaryButton(
              label: _isSaving
                  ? 'সেভ হচ্ছে...'
                  : _isEditing
                  ? 'ওয়ালেট আপডেট করুন'
                  : 'ওয়ালেট যোগ করুন',
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
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
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

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String type;
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
            Text(
              adminWalletTypeLabel(type),
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerTile extends StatelessWidget {
  const _OwnerTile({
    required this.owner,
    required this.selected,
    required this.onTap,
  });

  final AdminUser owner;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onTap(),
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.primary,
      title: Text(
        owner.name,
        style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
      ),
      subtitle: Text(
        owner.role.shortLabel,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.text3,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
