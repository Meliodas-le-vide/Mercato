import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/admin/data/admin_repository.dart';
import 'package:mercato_frontend/features/admin/domain/admin_models.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _repository = AdminRepository(DioClient());

  String? _statusFilter = 'OPEN';
  List<AdminReportEntry> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Map<String?, String> _statusTabs = {
    'OPEN': 'Ouverts',
    'REVIEWED': 'Traités',
    'DISMISSED': 'Rejetés',
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
      final reports = await _repository.listReports(status: _statusFilter);
      if (mounted) setState(() => _reports = reports);
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = 'Impossible de charger les signalements.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decide(AdminReportEntry report, {required bool dismiss}) async {
    await _repository.reviewReport(report.id, dismiss: dismiss);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        title: Text(
          'SIGNALEMENTS',
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
            height: 45,
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
                      fontSize: 16,
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
      return const Center(child: AppLoader(size: 90));
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.error, fontSize: 18),
        ),
      );
    }
    if (_reports.isEmpty) {
      return Center(
        child: Text(
          'Aucun signalement ici.',
          style: TextStyle(color: semantic.textSecondary, fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = _reports[index];
          final isOpen = report.status == 'OPEN';

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: semantic.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 15, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reportReasonLabels[report.reason] ?? report.reason,
                        style: TextStyle(
                          color: semantic.textPrimary,
                          fontWeight: context.weight(FontWeight.bold),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${report.reporterName} a signalé ${report.targetName} (${report.targetRole})',
                  style: TextStyle(color: semantic.textSecondary, fontSize: 12),
                ),
                if (report.details != null && report.details!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: semantic.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.details!,
                      style: TextStyle(
                        color: semantic.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (isOpen) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _decide(report, dismiss: true),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: semantic.textSecondary),
                          ),
                          child: Text(
                            'Rejeter',
                            style: TextStyle(
                              color: semantic.textSecondary,
                              fontWeight: context.weight(FontWeight.bold),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _decide(report, dismiss: false),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                          ),
                          child: Text(
                            'Marquer traité',
                            style: TextStyle(
                              color: AppColors.onGold,
                              fontWeight: context.weight(FontWeight.bold),
                              fontSize: 12,
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
}
