class ApiLoginRequest {
  final String email;
  final String password;


  final String clientType;

  const ApiLoginRequest({
    required this.email,
    required this.password,
    this.clientType = 'MOBILE',
  });

  Map<String, Object?> toJson() => {
        'email': email,
        'password': password,
        'clientType': clientType,
      };
}

//server gets dataaa
class ApiCreateEventRequest {
  final String title;
  final String description;
  final int capacity;

  const ApiCreateEventRequest({
    required this.title,
    required this.description,
    required this.capacity,
  });

  Map<String, Object?> toJson() => {
        'title': title,
        'description': description,
        'capacity': capacity,
      };
}

class ApiChangeEventStateRequest {
  final String state;

  const ApiChangeEventStateRequest({
    required this.state,
  });

  Map<String, Object?> toJson() => {
        'state': state,
      };
}

class ApiChangeCapacityRequest {
  final int capacity;

  const ApiChangeCapacityRequest({
    required this.capacity,
  });

  Map<String, Object?> toJson() => {
        'capacity': capacity,
      };
}


class ApiCreateRegistrationRequest {
  const ApiCreateRegistrationRequest();

  Map<String, Object?> toJson() => {};
}

class ApiCreateReviewRequest {
  final int rating;
  final String comment;

  const ApiCreateReviewRequest({
    required this.rating,
    required this.comment,
  });

  Map<String, Object?> toJson() => {
        'rating': rating,
        'comment': comment,
      };
}


class ApiChangeBanRequest {
  final bool isBanned;

  const ApiChangeBanRequest({
    required this.isBanned,
  });

  Map<String, Object?> toJson() => {
        'isBanned': isBanned,
      };
}

class ApiChangeUserReputationRequest {
  final double reputation;

  const ApiChangeUserReputationRequest({
    required this.reputation,
  });

  Map<String, Object?> toJson() => {
        'reputation': reputation,
      };
}
