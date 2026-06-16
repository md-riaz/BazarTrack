import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/config/api_config.dart';
import '../../../api/data/bazar_api_repositories.dart';
import '../../../../bootstrap.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.enabled) {
    return ApiReportRepository(client: ref.watch(bazarApiClientProvider));
  }
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
