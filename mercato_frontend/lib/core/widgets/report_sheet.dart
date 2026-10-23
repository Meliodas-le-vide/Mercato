import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/data/report_repository.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

/// Ouvre le formulaire de signalement d'un profil (motif + détails
/// optionnels) et envoie la requête. Accessible depuis n'importe quel écran
/// affichant le profil d'un autre utilisateur.
Future<void> showReportSheet(
  BuildContext context, {
  required int targetUserId,
  required String targetLabel,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReportSheetContent(
      targetUserId: targetUserId,
      targetLabel: targetLabel,
    ),
  );
}

class _ReportSheetContent extends StatefulWidget {
  final int targetUserId;
  final String targetLabel;

  const _ReportSheetContent({
    required this.targetUserId,
    required this.targetLabel,
  });

  @override
  State<_ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends State<_ReportSheetContent> {
  final _reportRepository = ReportRepository(DioClient());
  final _detailsController = TextEditingController();

  ReportReason? _selectedReason;
  bool _isSending = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    // ⚠️ Capture du Navigator AVANT le pop
    final navigator = Navigator.of(context);

    setState(() => _isSending = true);
    try {
      await _reportRepository.createReport(
        targetUserId: widget.targetUserId,
        reason: _selectedReason!,
        details: _detailsController.text,
      );

      if (!mounted) return;

      // Affiche le snackbar (messenger racine) PUIS ferme le sheet
      AppSnackbar.success(
        context,
        'Signalement envoyé. Merci de nous aider à garder l\'app fiable.',
      );
      navigator.pop();
    } catch (e) {
      debugPrint('Erreur createReport: $e');
      if (!mounted) return;

      AppSnackbar.error(
        context,
        'Impossible d\'envoyer le signalement pour le moment.',
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- Poignée --------
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.textTertiary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // -------- Titre --------
              Text(
                'Signaler ${widget.targetLabel}',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: context.weight(FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pourquoi signales-tu ce profil ?',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),

              // -------- Raisons --------
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportReason.values.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return ChoiceChip(
                    label: Text(reason.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedReason = reason),
                    selectedColor: AppColors.primaryYellow,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.onGold : colors.textPrimary,
                      fontWeight: isSelected
                          ? context.weight(FontWeight.bold)
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                    backgroundColor: colors.surfaceVariant,
                    side: BorderSide(color: colors.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // -------- Détails optionnels --------
              TextField(
                controller: _detailsController,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Détails (optionnel)...',
                  hintStyle: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // -------- Bouton envoyer --------
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedReason == null || _isSending
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'ENVOYER LE SIGNALEMENT',
                          style: TextStyle(
                            fontWeight: context.weight(FontWeight.bold),
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
