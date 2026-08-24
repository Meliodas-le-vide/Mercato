class PlayerProfileModel {
  final int? id;
  final int userId;
  final String? position;
  final String? strongFoot;
  final String? birthDate; 
  final String? level;
  final String? currentClub;
  final String? city;
  final String? country;
  final String? bio;
  final int? height;
  final int? weight;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final int cardsYellow;
  final int cardsRed;
  final bool isProfileComplete;

  PlayerProfileModel({
    this.id,
    required this.userId,
    this.position,
    this.strongFoot,
    this.birthDate,
    this.level,
    this.currentClub,
    this.city,
    this.country,
    this.bio,
    this.height,
    this.weight,
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.cardsYellow = 0,
    this.cardsRed = 0,
    this.isProfileComplete = false,
  });

  factory PlayerProfileModel.fromJson(Map<String, dynamic> json) {
    return PlayerProfileModel(
      id: json['id'],
      userId: json['userId'],
      position: json['position'],
      strongFoot: json['strongFoot'],
      birthDate: json['birthDate'],
      level: json['level'],
      currentClub: json['currentClub'],
      city: json['city'],
      country: json['country'],
      bio: json['bio'],
      height: json['height'],
      weight: json['weight'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      matchesPlayed: json['matchesPlayed'] ?? 0,
      cardsYellow: json['cardsYellow'] ?? 0,
      cardsRed: json['cardsRed'] ?? 0,
      isProfileComplete: json['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (position != null) 'position': position,
      if (strongFoot != null) 'strongFoot': strongFoot,
      if (birthDate != null) 'birthDate': birthDate,
      if (level != null) 'level': level,
      if (currentClub != null) 'currentClub': currentClub,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
    };
  }

  PlayerProfileModel copyWith({
    String? position,
    String? strongFoot,
    String? birthDate,
    String? level,
    String? currentClub,
    String? city,
    String? country,
    String? bio,
    int? height,
    int? weight,
  }) {
    return PlayerProfileModel(
      id: id,
      userId: userId,
      position: position ?? this.position,
      strongFoot: strongFoot ?? this.strongFoot,
      birthDate: birthDate ?? this.birthDate,
      level: level ?? this.level,
      currentClub: currentClub ?? this.currentClub,
      city: city ?? this.city,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goals: goals,
      assists: assists,
      matchesPlayed: matchesPlayed,
      cardsYellow: cardsYellow,
      cardsRed: cardsRed,
      isProfileComplete: isProfileComplete,
    );
  }
}