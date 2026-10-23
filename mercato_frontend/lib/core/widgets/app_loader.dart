import 'package:flutter/material.dart';
import 'package:flutter_modern_animated_loader/flutter_animated_loader.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({super.key, this.size = 20.0, this.color});

  @override
  Widget build(BuildContext context) {
    return FlutterAnimatedLoader.quadSpin(
      color: color ?? AppColors.accentOrange,
      size: size,
    );
  }
}
