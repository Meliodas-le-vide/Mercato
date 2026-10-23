class EventOrganizer {
  final int id;
  final String firstname;
  final String lastname;
  final String? profileImage;

  EventOrganizer({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.profileImage,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory EventOrganizer.fromJson(Map<String, dynamic> json) {
    return EventOrganizer(
      id: json['id'],
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      profileImage: json['Profile_image'],
    );
  }
}

class EventModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String? description;
  final DateTime eventDate;
  final String location;
  final String organizerName;
  final EventOrganizer? organizer;
  final String createdAt;

  EventModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.description,
    required this.eventDate,
    required this.location,
    required this.organizerName,
    this.organizer,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'],
      description: json['description'],
      eventDate:
          DateTime.tryParse(json['eventDate']?.toString() ?? '') ??
          DateTime.now(),
      location: json['location'] ?? '',
      organizerName: json['organizerName'] ?? '',
      organizer: json['organizer'] != null
          ? EventOrganizer.fromJson(json['organizer'])
          : null,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  bool get isPast => eventDate.isBefore(DateTime.now());
}
