import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;
}

class AppBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Action du bouton central. Si null, la barre s'affiche sans bouton
  /// central ni encoche, avec les 4 onglets répartis sur toute la largeur.
  final VoidCallback? onFabPressed;
  final IconData fabIcon;
  final Color? fabColor;
  final Gradient? fabGradient;
  final Color fabIconColor;
  final Color? activeColor;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onFabPressed,
    this.fabIcon = Icons.add_rounded,
    this.fabColor,
    this.fabGradient,
    this.fabIconColor = Colors.white,
    this.activeColor,
  }) : assert(items.length == 4);

  /// Hauteur de la zone cliquable (hors encoche système).
  static const double barHeight = 64;
  static const double fabSize = 56;

  /// Espace entre le FAB et le bord de l'encoche.
  static const double _notchMargin = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = activeColor ?? AppColors.accentOrange;
    final inactiveColor = colors.textSecondary;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final showFab = onFabPressed != null;

    // Le FAB dépasse de la moitié de sa hauteur au-dessus de la barre.
    final fabOverflow = showFab ? fabSize / 2 : 0.0;
    final totalHeight = fabOverflow + barHeight + bottomInset;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Espace central réservé au FAB : toujours plus large que l'encoche,
        // pour que les onglets voisins ne débordent jamais dans le creux.
        final notchWidth = fabSize + _notchMargin * 2;
        final centerGap = math.max(
          notchWidth + 24,
          constraints.maxWidth * 0.22,
        );

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight + bottomInset,
                child: CustomPaint(
                  painter: _NotchedBarPainter(
                    color: colors.surface,
                    shadowColor: colors.shadow,
                    // En clair, la bordure du thème est trop pâle sur la surface :
                    // on prend un gris plus marqué pour détacher la barre.
                    borderColor: context.isDark
                        ? colors.border.withValues(alpha: 0.5)
                        : AppColors.navBorderLight,
                    borderWidth: context.isDark ? 0.5 : 1,
                    notchRadius: showFab ? fabSize / 2 + _notchMargin : 0,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                height: barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      _NavBarItem(
                        item: items[i],
                        selected: currentIndex == i,
                        onPressed: () => onTap(i),
                        selectedColor: accent,
                        defaultColor: inactiveColor,
                      ),
                    if (showFab) SizedBox(width: centerGap),
                    for (var i = 2; i < 4; i++)
                      _NavBarItem(
                        item: items[i],
                        selected: currentIndex == i,
                        onPressed: () => onTap(i),
                        selectedColor: accent,
                        defaultColor: inactiveColor,
                      ),
                  ],
                ),
              ),
              if (showFab)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _CenterFab(
                      size: fabSize,
                      icon: fabIcon,
                      fallbackColor: fabColor ?? accent,
                      gradient: fabGradient,
                      iconColor: fabIconColor,
                      onPressed: onFabPressed!,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CenterFab extends StatelessWidget {
  final double size;
  final IconData icon;
  final Color fallbackColor;
  final Gradient? gradient;
  final Color iconColor;
  final VoidCallback onPressed;

  const _CenterFab({
    required this.size,
    required this.icon,
    required this.fallbackColor,
    required this.onPressed,
    this.gradient,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? fallbackColor : null,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: fallbackColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onPressed;
  final Color selectedColor;
  final Color defaultColor;

  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onPressed,
    required this.selectedColor,
    required this.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : defaultColor;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkResponse(
          onTap: onPressed,
          radius: 32,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? selectedColor.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                // scaleDown : le libellé rétrécit plutôt que de déborder
                // sur les petits écrans ou avec une grande taille de police.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: selected
                          ? context.weight(FontWeight.w700)
                          : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre aux coins supérieurs arrondis avec une encoche circulaire
/// centrée sur le bord supérieur, dans laquelle se loge le FAB.
class _NotchedBarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final Color borderColor;
  final double borderWidth;
  final double notchRadius;

  static const double _cornerRadius = 22;

  _NotchedBarPainter({
    required this.color,
    required this.shadowColor,
    required this.borderColor,
    required this.borderWidth,
    required this.notchRadius,
  });

  Path _buildPath(Size size) {
    final host = Offset.zero & size;
    final rounded = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          host,
          topLeft: const Radius.circular(_cornerRadius),
          topRight: const Radius.circular(_cornerRadius),
        ),
      );
    if (notchRadius <= 0) return rounded;

    final guest = Rect.fromCircle(
      center: Offset(size.width / 2, 0),
      radius: notchRadius,
    );

    final notched = const CircularNotchedRectangle().getOuterPath(host, guest);

    return Path.combine(PathOperation.intersect, notched, rounded);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawShadow(path, shadowColor, 10, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(_NotchedBarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.notchRadius != notchRadius;
}
