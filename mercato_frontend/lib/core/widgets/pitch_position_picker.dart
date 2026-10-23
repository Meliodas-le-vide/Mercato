import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';

class PitchPositionPicker extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const PitchPositionPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const Map<String, Alignment> spots = {
    'GARDIEN': Alignment(0.0, 0.86),
    'LATERAL_GAUCHE': Alignment(-0.7, 0.5),
    'DEFENSEUR_CENTRAL': Alignment(0.0, 0.58),
    'LATERAL_DROIT': Alignment(0.7, 0.5),
    'MILIEU_DEFENSIF': Alignment(0.0, 0.22),
    'MILIEU_CENTRAL': Alignment(-0.45, -0.02),
    'MILIEU_OFFENSIF': Alignment(0.45, -0.02),
    'AILIER_GAUCHE': Alignment(-0.62, -0.56),
    'ATTAQUANT': Alignment(0.0, -0.78),
    'AILIER_DROIT': Alignment(0.62, -0.56),
  };

  @override
  State<PitchPositionPicker> createState() => _PitchPositionPickerState();
}

class _PitchPositionPickerState extends State<PitchPositionPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // ⚠️ Gradient vert "pelouse" volontaire : c'est le design
        // du picker de poste, indépendant du thème clair/sombre.
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [Color(0xFF1F7A47), Color(0xFF0F4A2A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------- En-tête : titre + badge sélection --------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TON POSTE PRINCIPAL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: context.weight(FontWeight.w800),
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  PlayerLabels.labelFor(
                    PlayerLabels.positions,
                    widget.selected,
                    fallback: 'À choisir',
                  ).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.onGold,
                    fontSize: 10,
                    fontWeight: context.weight(FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // -------- Terrain --------
          AspectRatio(
            aspectRatio: 1.35,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _PitchLinesPainter()),
                    ),
                    for (final entry in PitchPositionPicker.spots.entries)
                      Align(
                        alignment: entry.value,
                        child: _PositionDot(
                          isSelected: widget.selected == entry.key,
                          pulse: _pulse,
                          onTap: () => widget.onChanged(entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // -------- Aide --------
          const Text(
            'Touche une zone du terrain pour changer de poste',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PositionDot extends StatelessWidget {
  final bool isSelected;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _PositionDot({
    required this.isSelected,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: isSelected
            ? AnimatedBuilder(
                animation: pulse,
                builder: (context, _) {
                  final glow = 6 + pulse.value * 10;
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentOrange,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentOrange.withValues(
                            alpha: 0.7 - pulse.value * 0.4,
                          ),
                          blurRadius: glow,
                          spreadRadius: glow / 3,
                        ),
                      ],
                    ),
                  );
                },
              )
            : Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 1.3,
                  ),
                ),
              ),
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Ligne médiane
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Rond central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.17,
      paint,
    );

    // Surface de réparation haut + bas
    final boxW = size.width * 0.34;
    final boxH = size.height * 0.16;
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, 0, boxW, boxH),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, size.height - boxH, boxW, boxH),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
