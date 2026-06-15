import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/offline_queue_entry.dart';

class SettingsMockDataSource {
  const SettingsMockDataSource();

  List<OfflineQueueEntry> offlineQueueEntries() {
    return const [
      OfflineQueueEntry(
        id: 'q1',
        entityType: 'bazar_item',
        operation: 'update',
        entityLabel: 'দুধ ২ প্যাকেট — price: ১৩০',
        ageLabel: '৩ মিনিট আগে',
        retryCount: 0,
        status: OfflineQueueStatus.waiting,
      ),
      OfflineQueueEntry(
        id: 'q2',
        entityType: 'bazar_item',
        operation: 'update',
        entityLabel: 'ডিম ৩০টা — status: not_found',
        ageLabel: '৫ মিনিট আগে',
        retryCount: 0,
        status: OfflineQueueStatus.waiting,
      ),
      OfflineQueueEntry(
        id: 'q3',
        entityType: 'money_return_request',
        operation: 'create',
        entityLabel: 'ফেরত অনুরোধ — ৳ ৫০',
        ageLabel: '৮ মিনিট আগে',
        retryCount: 1,
        status: OfflineQueueStatus.waiting,
      ),
      OfflineQueueEntry(
        id: 'q4',
        entityType: 'money_entry',
        operation: 'create',
        entityLabel: 'ফান্ড থেকে দিলাম — ৳ ৩,০০০',
        ageLabel: '১২ মিনিট আগে',
        retryCount: 2,
        status: OfflineQueueStatus.failed,
      ),
      OfflineQueueEntry(
        id: 'q5',
        entityType: 'comment',
        operation: 'create',
        entityLabel: 'Aarong পাইনি, local নিয়েছি',
        ageLabel: '১৫ মিনিট আগে',
        retryCount: 0,
        status: OfflineQueueStatus.waiting,
      ),
    ];
  }

  String pendingLabel(int count) {
    return '${CurrencyFormatter.toBanglaDigits(count.toString())}টি item পাঠানো বাকি আছে';
  }
}
