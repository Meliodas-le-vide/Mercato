import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';

class GoldButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final double fontSize;
  final bool loading;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.width = 270,
    this.fontSize = 18,
    this.loading = false,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.height / 2;
    final disabled = widget.onPressed == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: AppColors.goldGradient,
            stops: AppColors.goldGradientStops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentOrange.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : 200.0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final travel = width + 80;
                          return Positioned(
                            left: -40 + _controller.value * travel,
                            top: -12,
                            bottom: -12,
                            width: 30,
                            child: Transform.rotate(
                              angle: -0.4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.55),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.loading
                            ? const [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: AppLoader(size: 18),
                                ),
                              ]
                            : [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: 16,
                                    color: AppColors.onGold,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: AppColors.onGold,
                                    fontSize: widget.fontSize,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
