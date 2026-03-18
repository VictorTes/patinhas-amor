import 'dart:convert';
import 'package:http/http.dart' as http;

import 'constants.dart';

/// Centralized HTTP client for making API requests.
///
/// This class handles common HTTP operations like GET, POST, PATCH
/// with standardized error handling and timeout configuration.
class ApiClient {
  /// HTTP client instance
  final http.Client _client;

  /// Creates an ApiClient instance.
  ///
  /// Optionally accepts a custom HTTP client for testing purposes.
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Performs a GET request to the specified endpoint.
  ///
  /// [endpoint] is the API path (e.g., '/occurrences').
  /// Returns the decoded JSON response.
  /// Throws an exception on failure.
  Future<dynamic> get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers,
    );
    return _processResponse(response);
  }

  /// Performs a POST request to the specified endpoint.
  ///
  /// [endpoint] is the API path.
  /// [body] is the request payload (will be JSON encoded).
  /// Returns the decoded JSON response.
  /// Throws an exception on failure.
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  /// Performs a PATCH request to the specified endpoint.
  ///
  /// [endpoint] is the API path.
  /// [body] is the request payload (will be JSON encoded).
  /// Returns the decoded JSON response.
  /// Throws an exception on failure.
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  /// Returns the default headers for API requests.
  Future<Map<String, String>> get _headers async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Authorization header can be added here when authentication is implemented
    };
  }

  /// Processes the HTTP response and handles errors.
  ///
  /// Returns the decoded JSON body for successful responses.
  /// Throws an exception for error status codes.
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  /// Closes the HTTP client when no longer needed.
  void dispose() {
    _client.close();
  }
}
