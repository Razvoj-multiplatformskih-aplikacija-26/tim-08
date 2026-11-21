import 'api_models.dart';

class ApiLoginResponse {
  final String accessToken;
  final DateTime expiresAt;
  final ApiUserDto user;

  const ApiLoginResponse({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  factory ApiLoginResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return ApiLoginResponse(
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(
        json['expiresAt'] as String,
      ),
      user: ApiUserDto.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toIso8601String(),
    'user': user.toJson(),
  };
}