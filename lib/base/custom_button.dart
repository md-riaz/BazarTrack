import 'package:flutter_boilerplate/util/dimensions.dart';
import 'package:flutter_boilerplate/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomButton extends StatelessWidget {
  final Function? onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  const CustomButton({
    super.key, this.onPressed, required this.buttonText, this.transparent = false, this.margin, this.width,
    this.height, this.fontSize, this.radius = 5, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      backgroundColor: onPressed == null ? Theme.of(context).disabledColor : transparent
          ? Colors.transparent : Theme.of(context).primaryColor,
      minimumSize: Size(width ?? context.width, height ?? 50),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Center(child: SizedBox(width: width ?? context.width, child: Padding(
      padding: margin ?? EdgeInsets.all(0),
      child: TextButton(
        onPressed: onPressed != null ? onPressed!() : null,
        style: flatButtonStyle,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon != null ? Padding(
            padding: EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
            child: Icon(icon, color: transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor),
          ) : SizedBox(),
          Text(buttonText, textAlign: TextAlign.center, style: robotoBold.copyWith(
            color: transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
            fontSize: fontSize ?? Dimensions.fontSizeLarge,
          )),
        ]),
      ),
    )));
  }
}