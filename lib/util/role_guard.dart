import 'package:bazar_track/features/auth/controller/auth_controller.dart';
import 'package:get/get.dart';

import '../base/custom_snackbar.dart';

class RoleGuard {
  static bool ensureOwner() {
    final auth = Get.find<AuthController>();
    if (!auth.isOwner) {
      showCustomSnackBar(isError: true,title: 'Access Denied', 'Only owners can perform this action');
      return false;
    }
    return true;
  }
}
