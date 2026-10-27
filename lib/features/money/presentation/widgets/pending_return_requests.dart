import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/services/role_permissions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/money_return_request.dart';
import '../providers/money_providers.dart';

class PendingReturnRequests extends ConsumerWidget {
  const PendingReturnRequests({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null || !RolePermissions.canConfirmMoneyReturn(user.role)) {
      return const SizedBox.shrink();
    }
    final requests = ref.watch(pendingReturnRequestsProvider);
    return requests.when(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'অপেক্ষমাণ ফেরত অনুরোধ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final request in items)
                  _ReturnRequestTile(request: request),
              ],
            ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton(
          onPressed: () => ref.invalidate(pendingReturnRequestsProvider),
          child: const Text('ফেরত অনুরোধ আবার লোড করুন'),
        ),
      ),
    );
  }
}

class _ReturnRequestTile extends ConsumerWidget {
  const _ReturnRequestTile({required this.request});

  final MoneyReturnRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(CurrencyFormatter.format(request.amount)),
        subtitle: Text(request.note ?? 'Assistant ${request.assistantId}'),
        trailing: FilledButton(
          onPressed: () async {
            try {
              await ref.read(confirmReturnRequestProvider(request.id).future);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ফেরত টাকা নিশ্চিত হয়েছে')),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('নিশ্চিত করা যায়নি')),
                );
              }
            }
          },
          child: const Text('নিশ্চিত করুন'),
        ),
      ),
    );
  }
}
