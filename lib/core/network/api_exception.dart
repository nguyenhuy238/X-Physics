class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  final String message;
  final int? statusCode;
  final List<Map<String, dynamic>> errors;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
