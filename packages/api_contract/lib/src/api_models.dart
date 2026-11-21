class ApiUserDto {
  final int id;
  final String name;
  final String email;
  final String role;
  final double reputation;
  final bool isBanned;

  const ApiUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.reputation,
    required this.isBanned,
  });

  factory ApiUserDto.fromJson(Map<String, dynamic> json) {
    return ApiUserDto(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      reputation: (json['reputation'] as num).toDouble(),
      isBanned: json['isBanned'] as bool,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'reputation': reputation,
        'isBanned': isBanned,
      };
}

class ApiPublicUserDto {
  const ApiPublicUserDto({
    required this.id,
    required this.name,
    required this.role,
    required this.reputation,
  });

  final int id;
  final String name;
  final String role;
  final double reputation;

  factory ApiPublicUserDto.fromJson(Map<String, dynamic> json) =>
      ApiPublicUserDto(
        id: json['id'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
        reputation: (json['reputation'] as num).toDouble(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'reputation': reputation,
      };
}

class ApiEventDto {
  final int id;
  final int hostId;
  final String title;
  final String state;
  final int capacity;
  final double hostReputation;
  final String description;

  const ApiEventDto({
    required this.id,
    required this.hostId,
    required this.title,
    required this.state,
    required this.capacity,
    required this.hostReputation,
    required this.description,
  });

  factory ApiEventDto.fromJson(Map<String, dynamic> json) {
    return ApiEventDto(
      id: json['id'] as int,
      hostId: json['hostId'] as int,
      title: json['title'] as String,
      state: json['state'] as String,
      capacity: json['capacity'] as int,
      hostReputation: (json['hostReputation'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'hostId': hostId,
        'title': title,
        'state': state,
        'capacity': capacity,
        'hostReputation': hostReputation,
        'description': description,
      };
}

class ApiRegistrationDto {
  final int id;
  final int eventId;
  final int userId;
  final String status;

  const ApiRegistrationDto({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
  });

  factory ApiRegistrationDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ApiRegistrationDto(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      userId: json['userId'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        'status': status,
      };
}

class ApiReviewDto {
  final int id;
  final int eventId;
  final int authorId;
  final int rating;
  final String comment;

  const ApiReviewDto({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.rating,
    required this.comment,
  });

  factory ApiReviewDto.fromJson(Map<String, dynamic> json) {
    return ApiReviewDto(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      authorId: json['authorId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'eventId': eventId,
        'authorId': authorId,
        'rating': rating,
        'comment': comment,
      };
}
