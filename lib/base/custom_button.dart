import 'package:bazar_track/util/colors.dart';
import 'package:bazar_track/util/styles.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttonText;
  final bool loading;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final Color? btnColor;
  final bool shrink;

  const CustomButton({
    super.key,
    this.onPressed,
    required this.buttonText,
    this.loading = false,
    this.transparent = false,
    this.margin,
    this.width,
    this.height,
    this.fontSize,
    this.radius = 12,
    this.icon,
    this.btnColor = AppColors.primary,
    this.shrink = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final bgColor = disabled ? Theme.of(context).disabledColor : btnColor;

    final buttonChild = loading
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: transparent
            ? Theme.of(context).primaryColor
            : Theme.of(context).cardColor,
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min, // 🔹 shrink content horizontally
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: transparent
                ? Theme.of(context).primaryColor
                : Theme.of(context).cardColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          buttonText,
          style: robotoBold.copyWith(
            color: transparent
                ? Theme.of(context).primaryColor
                : Theme.of(context).cardColor,
            fontSize: fontSize ?? 16,
          ),
        ),
      ],
    );

    return Container(
      margin: margin,
      child: shrink
          ? TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: transparent ? Colors.transparent : bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: buttonChild,
      )
          : SizedBox(
        width: width ?? double.infinity,
        height: height ?? 50,
        child: TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            backgroundColor: transparent ? Colors.transparent : bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: buttonChild,
        ),
      ),
    );
  }
}
