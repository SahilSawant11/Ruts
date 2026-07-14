/// Thrown by repositories when an API call fails, wraps the underlying
/// cause but exposes a short, user-safe message for the UI to display
/// directly (e.g. in a SnackBar) without leaking stack traces.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.network() =>
      const ApiException('Could not reach the server. Check your connection and try again.');

  factory ApiException.fromStatusCode(int code) {
    if (code == 404) return const ApiException('Not found.', statusCode: 404);
    if (code >= 500) return ApiException('Server error ($code). Please try again.', statusCode: code);
    return ApiException('Request failed ($code).', statusCode: code);
  }

  @override
  String toString() => message;
}
