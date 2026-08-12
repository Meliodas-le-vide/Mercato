enum UserRole {
  player,
  recruiter,
  clubAgent,
  admin;

  // Convertit la chaîne de caractères venant de Sequelize vers l'enum Dart
  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'RECRUITER':
        return UserRole.recruiter;
      case 'CLUB_AGENT':
        return UserRole.clubAgent;
      case 'ADMIN':
        return UserRole.admin;
      case 'PLAYER':
      default:
        return UserRole.player;
    }
  }

  // Convertit l'enum Dart vers le format attendu par le backend Sequelize
  String toBackendString() {
    switch (this) {
      case UserRole.recruiter:
        return 'RECRUITER';
      case UserRole.clubAgent:
        return 'CLUB_AGENT';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.player:
        return 'PLAYER';
    }
  }
}

class UserModel {
  final int id;
  final String lastname;
  final String firstname;
  final String email;
  final String? phone;
  final UserRole role;
  final bool isVerified;
  final String? refreshToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.lastname,
    required this.firstname,
    required this.email,
    this.phone,
    required this.role,
    required this.isVerified,
    this.refreshToken,
    this.createdAt,
    this.updatedAt,
  });

  // Nom complet (Nom + Prénom)
  String get fullName => '$firstname $lastname';

  // Getters d'aide pour tester rapidement les rôles
  bool get isPlayer => role == UserRole.player;
  bool get isRecruiter => role == UserRole.recruiter || role == UserRole.clubAgent;
  bool get isAdmin => role == UserRole.admin;

  /// Fabrique un UserModel à partir de la réponse JSON de l'API Node.js/Sequelize
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      lastname: json['lastname'] ?? '',
      firstname: json['firstname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: UserRole.fromString(json['role'] ?? 'PLAYER'),
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      refreshToken: json['refreshToken'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  /// Convertit un UserModel en objet JSON pour les requêtes POST / PUT
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastname': lastname,
      'firstname': firstname,
      'email': email,
      'phone': phone,
      'role': role.toBackendString(),
      'is_verified': isVerified,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }

  /// Permet de copier un UserModel en modifiant uniquement certains champs
  UserModel copyWith({
    int? id,
    String? lastname,
    String? firstname,
    String? email,
    String? phone,
    UserRole? role,
    bool? isVerified,
    String? refreshToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      lastname: lastname ?? this.lastname,
      firstname: firstname ?? this.firstname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      refreshToken: refreshToken ?? this.refreshToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}