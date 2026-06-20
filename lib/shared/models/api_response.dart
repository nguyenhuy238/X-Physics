class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors = const [],
  });

  final bool success;
  final String message;
  final T? data;
  final List<ApiFieldError> errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? parseData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: parseData == null ? null : parseData(json['data']),
      errors: ((json['errors'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ApiFieldError.fromJson)
          .toList(),
    );
  }
}

class ApiFieldError {
  const ApiFieldError({this.field, required this.message});

  final String? field;
  final String message;

  factory ApiFieldError.fromJson(Map<String, dynamic> json) => ApiFieldError(
    field: json['field'] as String?,
    message: json['message'] as String? ?? '',
  );
}
