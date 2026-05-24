import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(appDatabaseProvider));
});

final monthlyReportProvider = StreamProvider.family<ReportSummary, String>((
  ref,
  periodMonth,
) {
  return ref.watch(reportRepositoryProvider).watchMonthlySummary(periodMonth);
});

String currentPeriodMonth() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}
