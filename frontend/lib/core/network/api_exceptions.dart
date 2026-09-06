class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}
