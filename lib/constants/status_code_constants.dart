/// HTTP Status Code Constants
/// Centralized status codes for API responses
class StatusCodeConstants {
  // =========================
  // Success Codes (Backend)
  // =========================
  //
  // This backend uses:
  // - HTTP statusCode: 200 (transport success)
  // - JSON body statusCode: 201 (application success)
  //
  // Keep both centrally so callers don’t hardcode magic numbers.

  /// HTTP transport success
  static const int httpSuccess = 200;

  /// API JSON body success (`responseBody['statusCode']`)
  static const int success = 201;

  /// Accepted (e.g. goal already added)
  static const int accepted = 202;
  // static const int noContent = 204;

  // Client Error Status Codes (4xx)
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;

  // Server Error Status Codes (5xx)
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;

  // Helper methods
  /// HTTP transport success.
  ///
  /// Historically the backend only returned HTTP 200 for successful
  /// application responses, but newer endpoints (e.g. create / meetings)
  /// sometimes use HTTP 201 for "Created". We treat **both** 200 and 201
  /// as a successful transport layer and rely on [isApiSuccess] to enforce
  /// the stricter `statusCode == 201` rule in the JSON body.
  static bool isHttpSuccess(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode == httpSuccess || statusCode == success;
  }

  /// API JSON-body success (must be 201)
  static bool isApiSuccess(int? statusCode) {
    return statusCode == success;
  }

  /// Check if status code indicates success (2xx range)
  static bool isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Check if status code indicates client error (4xx range)
  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }

  /// Check if status code indicates server error (5xx range)
  static bool isServerError(int statusCode) {
    return statusCode >= 500 && statusCode < 600;
  }

  /// Check if status code indicates an error (4xx or 5xx range)
  static bool isError(int statusCode) {
    return isClientError(statusCode) || isServerError(statusCode);
  }
}
