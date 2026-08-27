import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';

class PlayerSearchResult {
  final PlayerProfileModel profile;
  final UserModel user;
  final bool isFavorited;

  PlayerSearchResult({
    required this.profile,
    required this.user,
    this.isFavorited = false,
  });

  factory PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    return PlayerSearchResult(
      profile: PlayerProfileModel.fromJson(json),
      user: UserModel.fromJson(json['User'] ?? {}),
      isFavorited: json['isFavorited'] ?? false,
    );
  }

  int? get age {
    final birthDate = profile.birthDate;
    if (birthDate == null || birthDate.isEmpty) return null;
    try {
      final birth = DateTime.parse(birthDate);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String get fullName => '${user.firstname} ${user.lastname}'.trim();
}