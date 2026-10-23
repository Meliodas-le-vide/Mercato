import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';

/// Motifs de signalement proposés à l'utilisateur, alignés sur l'ENUM
/// `reason` du backend (mercato_backend/src/models/Report.js).
enum ReportReason {
  fakeProfile('FAKE_PROFILE', 'Profil suspect ou faux'),
  suspiciousContact('SUSPICIOUS_CONTACT', 'Contact ou message suspect'),
  inappropriateContent('INAPPROPRIATE_CONTENT', 'Contenu inapproprié'),
  other('OTHER', 'Autre raison');

  final String apiValue;
  final String label;

  const ReportReason(this.apiValue, this.label);
}

class ReportRepository {
  final DioClient _dioClient;

  ReportRepository(this._dioClient);

  Future<void> createReport({
    required int targetUserId,
    required ReportReason reason,
    String? details,
  }) async {
    await _dioClient.dio.post(
      ApiEndpoints.reports,
      data: {
        'targetUserId': targetUserId,
        'reason': reason.apiValue,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }
}
