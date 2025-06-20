import 'package:flutter_boilerplate/base/custom_button.dart';
import 'package:flutter_boilerplate/util/dimensions.dart';
import 'package:flutter_boilerplate/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmationDialog extends StatelessWidget {
  final String icon;
  final String? title;
  final String description;
  final Function onYesPressed;
  final bool isLogOut;
  final Function? onNoPressed;
  const ConfirmationDialog({super.key, required this.icon, this.title, required this.description, required this.onYesPressed,
    this.isLogOut = false, this.onNoPressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      insetPadding: EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: SizedBox(width: 500, child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Image.asset(icon, width: 50, height: 50),
          ),

          title != null ? Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Text(
              title ?? '', textAlign: TextAlign.center,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.red),
            ),
          ) : SizedBox(),

          Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Text(description, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge), textAlign: TextAlign.center),
          ),
          SizedBox(height: Dimensions.paddingSizeLarge),

          Row(children: [
            Expanded(child: TextButton(
              onPressed: () => isLogOut ? onYesPressed() : onNoPressed != null ? onNoPressed!() : Get.back(),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.3), minimumSize: Size(context.width, 40), padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              ),
              child: Text(
                isLogOut ? 'yes'.tr : 'no'.tr, textAlign: TextAlign.center,
                style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
              ),
            )),
            SizedBox(width: Dimensions.paddingSizeLarge),

            Expanded(child: CustomButton(
              buttonText: isLogOut ? 'no'.tr : 'yes'.tr,
              onPressed: () => isLogOut ? Get.back() : onYesPressed(),
              radius: Dimensions.radiusSmall, height: 40,
            )),
          ]),

        ]),
      )),
    );
  }
}
