import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/status_chip.dart';

String bazarStatusLabel(BazarStatus status) {
  switch (status) {
    case BazarStatus.open:
      return 'চলতেছে';
    case BazarStatus.draft:
      return 'খোলা';
    case BazarStatus.closed:
      return 'শেষ';
    case BazarStatus.cancelled:
      return 'বাতিল';
  }
}

String itemStatusLabel(ItemStatus status) {
  switch (status) {
    case ItemStatus.pending:
      return 'অপেক্ষায়';
    case ItemStatus.done:
      return 'কেনা';
    case ItemStatus.notFound:
      return 'পাওয়া যায়নি';
    case ItemStatus.cancelled:
      return 'বাতিল';
  }
}

StatusChip bazarStatusChip(BazarStatus status) {
  switch (status) {
    case BazarStatus.open:
      return StatusChip(
        label: bazarStatusLabel(status),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.primary,
      );
    case BazarStatus.draft:
      return StatusChip(
        label: bazarStatusLabel(status),
        backgroundColor: AppColors.warningLight,
        foregroundColor: AppColors.warning,
      );
    case BazarStatus.closed:
      return StatusChip(
        label: bazarStatusLabel(status),
        backgroundColor: AppColors.positiveLight,
        foregroundColor: AppColors.positive,
      );
    case BazarStatus.cancelled:
      return StatusChip(
        label: bazarStatusLabel(status),
        backgroundColor: AppColors.negativeLight,
        foregroundColor: AppColors.negative,
      );
  }
}

StatusChip itemStatusChip(ItemStatus status) {
  switch (status) {
    case ItemStatus.done:
      return StatusChip(
        label: itemStatusLabel(status),
        backgroundColor: AppColors.positiveLight,
        foregroundColor: AppColors.positive,
      );
    case ItemStatus.notFound:
      return StatusChip(
        label: itemStatusLabel(status),
        backgroundColor: AppColors.negativeLight,
        foregroundColor: AppColors.negative,
      );
    case ItemStatus.cancelled:
      return StatusChip(
        label: itemStatusLabel(status),
        backgroundColor: AppColors.surface3,
        foregroundColor: AppColors.text3,
      );
    case ItemStatus.pending:
      return StatusChip(
        label: itemStatusLabel(status),
        backgroundColor: AppColors.warningLight,
        foregroundColor: AppColors.warning,
      );
  }
}
