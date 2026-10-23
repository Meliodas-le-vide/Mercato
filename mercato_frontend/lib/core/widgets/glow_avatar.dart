import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

class GlowAvatar extends StatefulWidget {
  final double radius;
  final String? imageUrl;
  final Widget? placeholder;

  const GlowAvatar({
    super.key,
    this.radius = 32,
    this.imageUrl,
    this.placeholder,
  });

  @override
  State<GlowAvatar> createState() => _GlowAvatarState();
}

class _GlowAvatarState extends State<GlowAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _glow = Tween<double>(
      begin: 0.3,
      end: 0.65,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    final size = widget.radius * 2;

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentOrange, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: _glow.value),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipOval(
        child: hasImage
            ? Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(colors),
              )
            : _fallback(colors),
      ),
    );
  }

  Widget _fallback(AppSemanticColors colors) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A3D5C), Color(0xFF16233C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child:
            widget.placeholder ??
            Icon(
              Icons.person,
              size: widget.radius * 0.9,
              color: Colors.white.withValues(alpha: 0.54),
            ),
      ),
    );
  }
}
