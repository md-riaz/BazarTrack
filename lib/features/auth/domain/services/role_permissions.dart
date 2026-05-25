import '../../../../shared/models/app_enums.dart';

class RolePermissions {
  const RolePermissions._();

  static bool canAccessAdmin(UserRole role) => role == UserRole.admin;

  static bool canAccessReports(UserRole role) =>
      role == UserRole.owner || role == UserRole.admin;

  static bool canRecordMoneyEntry(UserRole role) =>
      role == UserRole.owner || role == UserRole.admin;

  static bool canAddDirectExpense(UserRole role) =>
      role == UserRole.assistant || role == UserRole.admin;

  static bool canSeeReportsTab(UserRole role) => canAccessReports(role);

  static bool canSeeAdminMenu(UserRole role) => canAccessAdmin(role);

  static String label(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Admin',
      UserRole.owner => 'Owner',
      UserRole.assistant => 'Assistant',
    };
  }
}
