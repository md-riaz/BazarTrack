import '../entities/report_summary.dart';

abstract class ReportRepository {
  Stream<ReportSummary> watchMonthlySummary(String periodMonth);
}
