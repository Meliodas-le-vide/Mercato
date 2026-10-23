import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wrapper pour les pages d'onglet : fond + safe area top seulement.
/// (le bottom nav incurvé gère le bas)
class HomoraPage extends StatelessWidget {
  const HomoraPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.background,
      child: SafeArea(bottom: false, child: child),
    );
  }
}

/// Surface blanche avec ombre légère + bordure, utilisé partout dans Homora.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.onTap,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: border ? BorderSide(color: colors.border) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}
