/// Un compte utilisateur tel que vu par l'admin (tous rôles confondus),
/// pour la liste de modération et le bannissement.
class AdminUserModel {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? phone;
  final String role;
  final bool isBanned;
  final String? bannedReason;

  AdminUserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.phone,
    required this.role,
    required this.isBanned,
    this.bannedReason,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'],
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'USER',
      isBanned: json['isBanned'] ?? false,
      bannedReason: json['bannedReason'],
    );
  }
}

class AdminRecruiterEntry {
  final int profileId;
  final int userId;
  final String? organizationName;
  final String? organizationType;
  final String? jobTitle;
  final String? recruitmentZone;
  final String? licenseNumber;
  final String? identityDocumentUrl;
  final String verificationStatus;
  final String ownerName;
  final String ownerEmail;

  AdminRecruiterEntry({
    required this.profileId,
    required this.userId,
    this.organizationName,
    this.organizationType,
    this.jobTitle,
    this.recruitmentZone,
    this.licenseNumber,
    this.identityDocumentUrl,
    required this.verificationStatus,
    required this.ownerName,
    required this.ownerEmail,
  });

  factory AdminRecruiterEntry.fromJson(Map<String, dynamic> json) {
    final user = json['User'] as Map<String, dynamic>?;
    return AdminRecruiterEntry(
      profileId: json['id'],
      userId: json['userId'],
      organizationName: json['organizationName'],
      organizationType: json['organizationType'],
      jobTitle: json['jobTitle'],
      recruitmentZone: json['recruitmentZone'],
      licenseNumber: json['licenseNumber'],
      identityDocumentUrl: json['identityDocumentUrl'],
      verificationStatus: json['verificationStatus'] ?? 'PENDING',
      ownerName: user != null
          ? '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim()
          : '',
      ownerEmail: user?['email'] ?? '',
    );
  }
}

/// Une entrée de la liste des signalements côté admin.
class AdminReportEntry {
  final int id;
  final String reason;
  final String? details;
  final String status;
  final String reporterName;
  final String targetName;
  final String targetEmail;
  final String targetRole;
  final int targetUserId;
  final String createdAt;

  AdminReportEntry({
    required this.id,
    required this.reason,
    this.details,
    required this.status,
    required this.reporterName,
    required this.targetName,
    required this.targetEmail,
    required this.targetRole,
    required this.targetUserId,
    required this.createdAt,
  });

  factory AdminReportEntry.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final target = json['target'] as Map<String, dynamic>?;
    return AdminReportEntry(
      id: json['id'],
      reason: json['reason'] ?? 'OTHER',
      details: json['details'],
      status: json['status'] ?? 'OPEN',
      reporterName: reporter != null
          ? '${reporter['firstname'] ?? ''} ${reporter['lastname'] ?? ''}'
                .trim()
          : 'Inconnu',
      targetName: target != null
          ? '${target['firstname'] ?? ''} ${target['lastname'] ?? ''}'.trim()
          : 'Inconnu',
      targetEmail: target?['email'] ?? '',
      targetRole: target?['role'] ?? '',
      targetUserId: target?['id'] ?? json['targetUserId'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

const Map<String, String> reportReasonLabels = {
  'FAKE_PROFILE': 'Profil suspect ou faux',
  'SUSPICIOUS_CONTACT': 'Contact ou message suspect',
  'INAPPROPRIATE_CONTENT': 'Contenu inapproprié',
  'OTHER': 'Autre raison',
};
