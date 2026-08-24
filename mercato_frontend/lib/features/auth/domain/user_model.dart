import 'package:mercato_frontend/core/constants/api_endpoints.dart';

class UserModel {
  final int id;
  final String lastname;
  final String firstname;
  final String email;
  final String? phone;
  final String role;
  final String? Profile_image;

  UserModel({
    required this.id,
    required this.lastname,
    required this.firstname,
    required this.email,
    this.phone,
    required this.role,
    this.Profile_image,
  });

  /// Getter qui garantit le renvoi d'une URL HTTP/HTTPS complète
  String? get fullProfileImageUrl {
    if (Profile_image == null || Profile_image!.trim().isEmpty) return null;
    
    // Si c'est déjà une URL web distante (Cloudinary, S3, etc.)
    if (Profile_image!.startsWith('http://') || Profile_image!.startsWith('https://')) {
      return Profile_image;
    }
    
    // Si c'est un chemin relatif envoyé par Express/Multer
    final cleanPath = Profile_image!.startsWith('/') ? Profile_image! : '/$Profile_image';
    return '${ApiEndpoints.baseUrl}$cleanPath';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      lastname: json['lastname'] ?? '',
      firstname: json['firstname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      role: json['role'] ?? 'USER',
      Profile_image: json['Profile_image'] ?? json['ProfileImage'] ?? json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastname': lastname,
      'firstname': firstname,
      'email': email,
      'phone': phone,
      'role': role,
      'Profile_image': Profile_image,
    };
  }
}