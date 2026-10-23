import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/admin/data/admin_repository.dart';
import 'package:mercato_frontend/features/admin/domain/admin_models.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_labels.dart';

class AdminRecruitersScreen extends StatefulWidget {
  const AdminRecruitersScreen({super.key});

  @override
  State<AdminRecruitersScreen> createState() => _AdminRecruitersScreenState();
}

class _AdminRecruitersScreenState extends State<AdminRecruitersScreen> {
  final _repository = AdminRepository(DioClient());

  String? _statusFilter = 'PENDING';
  List<AdminRecruiterEntry> _recruiters = [];
  bool _isLoading = true;
  String? _processingProfileId;
  String? _errorMessage;

  static const Map<String?, String> _statusTabs = {
    'PENDING': 'En attente',
    'VERIFIED': 'Vérifiés',
    'REJECTED': 'Refusés',
    null: 'Tous',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recruiters = await _repository.listRecruiters(
        status: _statusFilter,
      );
      if (mounted) setState(() => _recruiters = recruiters);
    } catch (e) {
      if (mounted)
        setState(() => _errorMessage = 'Impossible de charger les recruteurs.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decide(
    AdminRecruiterEntry recruiter, {
    required bool approve,
  }) async {
    // ✅ Fix du type : conversion explicite int -> String
    setState(() => _processingProfileId = recruiter.profileId.toString());
    try {
      await _repository.verifyRecruiter(recruiter.profileId, approve: approve);
      if (mounted) {
        if (approve) {
          AppSnackbar.success(context, 'Recruteur validé.');
        } else {
          AppSnackbar.error(context, 'Recruteur refusé.');
        }
        _load();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Une erreur est survenue lors du traitement.',
        );
      }
    } finally {
      if (mounted) setState(() => _processingProfileId = null);
    }
  }

  void _openDocumentPreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: AppLoader()),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: const Text('Erreur lors du chargement du document.'),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        title: Text(
          'RECRUTEURS',
          style: TextStyle(
            letterSpacing: 1.1,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusTabs.entries.map((entry) {
                final isSelected = _statusFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _statusFilter = entry.key;
                      _load();
                    }),
                    selectedColor: AppColors.primaryYellow,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.onGold
                          : semantic.textPrimary,
                      fontWeight: isSelected
                          ? context.weight(FontWeight.bold)
                          : FontWeight.normal,
                      fontSize: 15,
                    ),
                    backgroundColor: semantic.surface,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(semantic)),
        ],
      ),
    );
  }

  Widget _buildBody(AppSemanticColors semantic) {
    if (_isLoading) {
      return const Center(child: AppLoader());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }
    if (_recruiters.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryYellow,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  'Aucun recruteur ici.',
                  style: TextStyle(
                    color: semantic.textSecondary,
                    fontSize: 16,
                    fontWeight: context.weight(FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _recruiters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final recruiter = _recruiters[index];
          final isPending = recruiter.verificationStatus == 'PENDING';
          final isProcessing =
              _processingProfileId == recruiter.profileId.toString();

          final labelType = recruiter.organizationType != null
              ? (RecruiterLabels.labelFor(
                  RecruiterLabels.organizationTypes,
                  recruiter.organizationType,
                ))
              : null;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: semantic.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organisation & Statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recruiter.organizationName?.isNotEmpty == true
                            ? recruiter.organizationName!
                            : 'Organisation non renseignée',
                        style: TextStyle(
                          color: semantic.textPrimary,
                          fontWeight: context.weight(FontWeight.bold),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildStatusBadge(recruiter.verificationStatus),
                  ],
                ),
                const SizedBox(height: 4),

                // Utilisateur & Type
                Text(
                  '${recruiter.ownerName} · ${recruiter.ownerEmail}',
                  style: TextStyle(color: semantic.textSecondary, fontSize: 14),
                ),
                if (labelType != null)
                  Text(
                    'Type : $labelType',
                    style: TextStyle(
                      color: semantic.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                Divider(
                  height: 20,
                  color: semantic.textSecondary.withOpacity(0.15),
                ),

                // Détails Métier & KYC
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCell(
                        semantic,
                        'FONCTION',
                        recruiter.jobTitle ?? 'Non renseigné',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailCell(
                        semantic,
                        'ZONE DE RECRUTEMENT',
                        recruiter.recruitmentZone ?? 'Non renseignée',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildDetailCell(
                  semantic,
                  'NUMÉRO DE LICENCE',
                  recruiter.licenseNumber ?? 'Non fourni',
                ),

                const SizedBox(height: 12),

                // Bouton Pièce Justificative
                if (recruiter.identityDocumentUrl != null &&
                    recruiter.identityDocumentUrl!.isNotEmpty)
                  InkWell(
                    onTap: () =>
                        _openDocumentPreview(recruiter.identityDocumentUrl!),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: AppColors.primaryYellow,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Voir la pièce d\'identité',
                            style: TextStyle(
                              color: AppColors.primaryYellow,
                              fontWeight: context.weight(FontWeight.bold),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'Aucune pièce d\'identité fournie',
                    style: TextStyle(
                      color: AppColors.error.withOpacity(0.8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                // Actions Admin
                if (isPending) ...[
                  const SizedBox(height: 16),
                  if (isProcessing)
                    const Center(child: AppLoader(size: 24))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _decide(recruiter, approve: false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: Text(
                              'Refuser',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: context.weight(FontWeight.bold),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _decide(recruiter, approve: true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            child: Text(
                              'Valider',
                              style: TextStyle(
                                fontWeight: context.weight(FontWeight.bold),
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCell(
    AppSemanticColors semantic,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: semantic.textSecondary,
            fontSize: 11,
            fontWeight: context.weight(FontWeight.w600),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: semantic.textPrimary,
            fontWeight: context.weight(FontWeight.w600),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final Color color = switch (status) {
      'VERIFIED' => AppColors.success,
      'REJECTED' => AppColors.error,
      _ => AppColors.warning,
    };
    final String label = switch (status) {
      'VERIFIED' => 'VÉRIFIÉ',
      'REJECTED' => 'REFUSÉ',
      _ => 'EN ATTENTE',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: context.weight(FontWeight.bold),
        ),
      ),
    );
  }
}
