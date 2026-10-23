enum RecruiterVerificationStatus {
  pending,
  verified,
  rejected;

  static RecruiterVerificationStatus fromJson(String? value) {
    switch (value) {
      case 'VERIFIED':
        return RecruiterVerificationStatus.verified;
      case 'REJECTED':
        return RecruiterVerificationStatus.rejected;
      case 'PENDING':
      default:
        return RecruiterVerificationStatus.pending;
    }
  }

  bool get isVerified => this == RecruiterVerificationStatus.verified;
}

class RecruiterProfileModel {
  final int? id;
  final int userId;
  final String? organizationName;
  final String? organizationType;
  final String? jobTitle;
  final String? recruitmentZone;
  final String? bio;
  final String? licenseNumber;
  final String? identityDocumentUrl;
  final bool isProfileComplete;
  final RecruiterVerificationStatus verificationStatus;

  RecruiterProfileModel({
    this.id,
    required this.userId,
    this.organizationName,
    this.organizationType,
    this.jobTitle,
    this.recruitmentZone,
    this.bio,
    this.licenseNumber,
    this.identityDocumentUrl,
    this.isProfileComplete = false,
    this.verificationStatus = RecruiterVerificationStatus.pending,
  });

  factory RecruiterProfileModel.fromJson(Map<String, dynamic> json) {
    return RecruiterProfileModel(
      id: json['id'],
      userId: json['userId'],
      organizationName: json['organizationName'],
      organizationType: json['organizationType'],
      jobTitle: json['jobTitle'],
      recruitmentZone: json['recruitmentZone'],
      bio: json['bio'],
      licenseNumber: json['licenseNumber'],
      identityDocumentUrl: json['identityDocumentUrl'],
      isProfileComplete: json['isProfileComplete'] ?? false,
      verificationStatus: RecruiterVerificationStatus.fromJson(
        json['verificationStatus'],
      ),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (organizationName != null) 'organizationName': organizationName,
      if (organizationType != null) 'organizationType': organizationType,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (recruitmentZone != null) 'recruitmentZone': recruitmentZone,
      if (bio != null) 'bio': bio,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (identityDocumentUrl != null)
        'identityDocumentUrl': identityDocumentUrl,
    };
  }
}
