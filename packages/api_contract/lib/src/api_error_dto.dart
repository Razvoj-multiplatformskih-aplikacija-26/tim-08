class ApiErrorDto {
  final String code;
  final Map<String, Object?> details;

  const ApiErrorDto({
    required this.code,
    this.details = const {},
  });

  factory ApiErrorDto.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];

    return ApiErrorDto(
      code: json['code'] as String,
      details: rawDetails == null
          ? const {}
          : Map<String, Object?>.from(rawDetails as Map),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'code': code,
      'details': details,
    };
  }
}