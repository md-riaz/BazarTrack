import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key, this.onAddUserTap});

  final VoidCallback? onAddUserTap;

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  var _tab = _AdminTab.users;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(
        title: 'Admin Panel',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        children: [
          _AdminTabs(
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          if (_tab == _AdminTab.users)
            _UsersSection(onAddUserTap: widget.onAddUserTap)
          else
            const _WalletsSection(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

enum _AdminTab { users, wallets }

class _AdminTabs extends StatelessWidget {
  const _AdminTabs({required this.selected, required this.onChanged});

  final _AdminTab selected;
  final ValueChanged<_AdminTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16).copyWith(bottom: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'ইউজার',
            icon: Icons.group_outlined,
            selected: selected == _AdminTab.users,
            onTap: () => onChanged(_AdminTab.users),
          ),
          _TabButton(
            label: 'ওয়ালেট',
            icon: Icons.account_balance_wallet_outlined,
            selected: selected == _AdminTab.wallets,
            onTap: () => onChanged(_AdminTab.wallets),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.primary : AppColors.text3,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? AppColors.primary : AppColors.text3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersSection extends ConsumerWidget {
  const _UsersSection({this.onAddUserTap});

  final VoidCallback? onAddUserTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return users.when(
      data: (items) => Column(
        children: [
          _SectionSummary(
            label:
                '${CurrencyFormatter.toBanglaDigits('${items.length}')}জন ইউজার',
            action: '+ নতুন ইউজার',
            onAction: onAddUserTap,
          ),
          _CardList(
            children: [
              for (var index = 0; index < items.length; index++)
                _UserTile(
                  user: items[index],
                  showDivider: index < items.length - 1,
                ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('ইউজার লোড করা যায়নি', style: AppTextStyles.body),
      ),
    );
  }
}

class _WalletsSection extends ConsumerWidget {
  const _WalletsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(adminWalletsProvider);
    return wallets.when(
      data: (items) => Column(
        children: [
          _SectionSummary(
            label:
                '${CurrencyFormatter.toBanglaDigits('${items.length}')}টি ওয়ালেট',
            action: '+ নতুন ওয়ালেট',
          ),
          _CardList(
            children: [
              for (var index = 0; index < items.length; index++)
                _WalletTile(
                  wallet: items[index],
                  showDivider: index < items.length - 1,
                ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('ওয়ালেট লোড করা যায়নি', style: AppTextStyles.body),
      ),
    );
  }
}

class _SectionSummary extends StatelessWidget {
  const _SectionSummary({
    required this.label,
    required this.action,
    this.onAction,
  });

  final String label;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onAction,
            child: Text(action, style: AppTextStyles.sectionAction),
          ),
        ],
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.showDivider});

  final AdminUser user;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = _roleColors(user.role);
    return Opacity(
      opacity: user.isActive ? 1 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: AppColors.surface3, width: 0.5),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            _Avatar(
              label: user.initials,
              background: user.isActive ? colors.$1 : AppColors.surface3,
              foreground: user.isActive ? colors.$2 : AppColors.text4,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user.phone,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text3,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Chip(
                  label: user.role.value,
                  background: colors.$1,
                  foreground: colors.$2,
                ),
                if (!user.isActive) ...[
                  const SizedBox(height: 4),
                  Text('INACTIVE', style: AppTextStyles.caption),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.showDivider});

  final AdminWallet wallet;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.surface3, width: 0.5),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(
                label: wallet.initials,
                background: AppColors.primaryLight,
                foreground: AppColors.primaryText,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
                    ),
                    Text(
                      wallet.type,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(wallet.balance),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: wallet.balance >= 0
                      ? AppColors.positive
                      : AppColors.negative,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Owner:',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text3,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 6),
              for (final owner in wallet.owners) ...[
                _Chip(
                  label: owner,
                  background: AppColors.primaryLight,
                  foreground: AppColors.primaryText,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.label,
    required this.background,
    required this.foreground,
    this.size = 34,
  });

  final String label;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: background,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: foreground,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

(Color, Color) _roleColors(AdminRole role) {
  return switch (role) {
    AdminRole.admin => (AppColors.negativeLight, AppColors.negativeDark),
    AdminRole.owner => (AppColors.primaryLight, AppColors.primaryText),
    AdminRole.assistant => (AppColors.positiveLight, AppColors.positiveDark),
  };
}
