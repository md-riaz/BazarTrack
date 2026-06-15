import 'package:bazar/features/auth/domain/services/role_permissions.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RolePermissions', () {
    test('monthly close is admin-only', () {
      expect(RolePermissions.canCloseMonthlyPeriod(UserRole.admin), isTrue);
      expect(RolePermissions.canCloseMonthlyPeriod(UserRole.owner), isFalse);
      expect(
        RolePermissions.canCloseMonthlyPeriod(UserRole.assistant),
        isFalse,
      );
    });

    test('owners keep report and money-entry access', () {
      expect(RolePermissions.canAccessReports(UserRole.owner), isTrue);
      expect(RolePermissions.canRecordMoneyEntry(UserRole.owner), isTrue);
    });
  });
}
