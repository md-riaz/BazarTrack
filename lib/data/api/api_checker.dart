import 'package:BazarTrack/base/custom_snackbar.dart';
import 'package:BazarTrack/controller/splash_controller.dart';
import 'package:get/get.dart';

class ApiChecker {
  static void checkApi(Response response) {
    if(response.statusCode == 401) {
      Get.find<SplashController>().removeSharedData();
      // TODO: Auth Login
    }else {
      showCustomSnackBar(response.statusText ?? '');
    }
  }
}