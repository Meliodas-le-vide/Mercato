import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/features/events/domain/event_model.dart';

String _formatFullDate(DateTime date) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year} à ${hour}h$minute';
}

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.icon,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'DETAIL DE L\'EVENEMENT',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  event.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      width: double.infinity,
                      color: AppColors.accentOrange.withValues(alpha: 0.08),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: AppColors.accentOrange,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Impossible de charger l\'image',
                          style: TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (event.isPast) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 12,
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ÉVÉNEMENT PASSÉ',
                      style: TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 10.5,
                        fontWeight: context.weight(FontWeight.w700),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              event.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: context.weight(FontWeight.w700),
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 15,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.organizerName,
                    style: TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 14,
                      fontWeight: context.weight(FontWeight.w700),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 20),

            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Date et heure',
              value: _formatFullDate(event.eventDate),
            ),
            const SizedBox(height: 18),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Lieu',
              value: event.location,
            ),
            if (event.organizer != null) ...[
              const SizedBox(height: 18),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Publié par',
                value: event.organizer!.fullName,
              ),
            ],

            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 28),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: context.weight(FontWeight.w700),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event.description!,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.accentOrange),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: context.weight(FontWeight.w600),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
