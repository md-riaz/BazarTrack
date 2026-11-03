import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../api/data/admin_audit_api.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key, this.api});

  final AdminAuditApi? api;

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  late final AdminAuditApi _api;
  late Future<_AuditData> _load;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AdminAuditApi(ref.read(bazarApiClientProvider));
    _load = _fetch();
  }

  Future<_AuditData> _fetch() async => (
    entries: await _api.listEntries(),
    reconciliation: await _api.reconcile(),
  );

  void _refresh() => setState(() => _load = _fetch());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('অডিট লগ')),
    body: FutureBuilder<_AuditData>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error, onRetry: _refresh);
        }
        final data = snapshot.requireData;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.entries.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return _AuditHealth(reconciliation: data.reconciliation);
              final entry = data.entries[index - 1];
              return _LedgerCard(
                entry: entry,
                onReverse: entry.isReversal ? null : () => _showReverse(entry),
              );
            },
          ),
        );
      },
    ),
  );

  Future<void> _showReverse(AdminAuditEntry entry) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReverseDialog(entry: entry),
    );
    if (!mounted || reason == null) return;
    try {
      await _api.reverse(entryId: entry.id, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রিভার্স লেনদেন তৈরি হয়েছে')));
      _refresh();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('রিভার্স করা যায়নি: $error')));
    }
  }
}

typedef _AuditData = ({List<AdminAuditEntry> entries, AdminAuditReconciliation reconciliation});

class _AuditHealth extends StatelessWidget {
  const _AuditHealth({required this.reconciliation});
  final AdminAuditReconciliation reconciliation;

  @override
  Widget build(BuildContext context) => Semantics(
    label: reconciliation.consistent ? 'অডিট মিলেছে' : 'অডিটে অসঙ্গতি আছে',
    child: Card(
      color: reconciliation.consistent ? const Color(0xFFE9F8EF) : const Color(0xFFFFECEC),
      child: ListTile(
        leading: Icon(reconciliation.consistent ? Icons.verified_outlined : Icons.warning_amber_rounded),
        title: Text(reconciliation.consistent ? 'হিসাব মিলেছে' : 'হিসাবে অসঙ্গতি আছে'),
        subtitle: Text(reconciliation.consistent ? 'সব balance snapshot যাচাই হয়েছে' : '${reconciliation.mismatches.length}টি সমস্যা পাওয়া গেছে'),
      ),
    ),
  );
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.entry, required this.onReverse});
  final AdminAuditEntry entry;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(_label(entry.type), style: Theme.of(context).textTheme.titleMedium)),
          Text(CurrencyFormatter.format(entry.signedAmount), style: TextStyle(color: entry.signedAmount < 0 ? AppColors.negative : AppColors.positive, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text('${entry.entryDate} • ${entry.id}'),
        Text('Balance: ${CurrencyFormatter.format(entry.balanceBefore)} → ${CurrencyFormatter.format(entry.balanceAfter)}'),
        if (entry.note?.isNotEmpty == true) Text(entry.note!),
        if (onReverse != null) ...[
          const SizedBox(height: 12),
          Semantics(
            label: 'লেনদেন উল্টান',
            button: true,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onReverse,
                icon: const Icon(Icons.undo),
                label: const Text('লেনদেন রিভার্স করুন'),
              ),
            ),
          ),
        ],
      ]),
    ),
  );
}

class _ReverseDialog extends StatefulWidget {
  const _ReverseDialog({required this.entry});
  final AdminAuditEntry entry;

  @override
  State<_ReverseDialog> createState() => _ReverseDialogState();
}

class _ReverseDialogState extends State<_ReverseDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('লেনদেন রিভার্স করবেন?'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('এই কাজটি একটি নতুন বিপরীত লেনদেন তৈরি করবে। মূল লেনদেন বদলাবে না।'),
      const SizedBox(height: 16),
      TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: 'কারণ লিখুন', hintText: 'রিভার্স করার কারণ অবশ্যই লিখুন'),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
      FilledButton(
        onPressed: _controller.text.trim().isEmpty ? null : () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('রিভার্স নিশ্চিত করুন'),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 40),
      const SizedBox(height: 12),
      const Text('অডিট লগ লোড করা যায়নি'),
      const SizedBox(height: 8),
      Text(error.toString(), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      SizedBox(height: 48, child: FilledButton(onPressed: onRetry, child: const Text('আবার চেষ্টা করুন'))),
    ]),
  ));
}

String _label(String type) => switch (type) {
  'fund_gave_money' => 'ফান্ড থেকে টাকা',
  'bazar_spend' => 'বাজার খরচ',
  'assistant_return_confirmed' => 'ফেরত টাকা',
  'adjustment' => 'সংশোধন',
  _ => type,
};
