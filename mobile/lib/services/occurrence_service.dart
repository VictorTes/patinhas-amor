import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:patinhas_amor/models/occurrence.dart';

/// Service class responsible for handling all API communication
/// related to occurrences (reports of animal abandonment or abuse).
///
/// This service interacts with the REST API to fetch and update
/// occurrence data.
class OccurrenceService {
  /// Base URL for the API
  ///
  /// In a production environment, this should be configured
  /// through environment variables or a configuration file.
  static const String _baseUrl = 'http:////10.0.2.2:3000';

  /// HTTP client for making API requests
  final http.Client _client;

  /// Creates an OccurrenceService instance.
  ///
  /// Optionally accepts a custom HTTP client for testing purposes.
  OccurrenceService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches all occurrences from the API.
  ///
  /// Returns a list of [Occurrence] objects.
  /// Throws an exception if the request fails.
  Future<List<Occurrence>> fetchOccurrences() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/occurrences'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Occurrence.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load occurrences. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load occurrences: $e');
    }
  }

  /// Updates the status of a specific occurrence.
  ///
  /// [id] is the occurrence identifier.
  /// [status] is the new status value (pending, in_progress, resolved).
  ///
  /// Throws an exception if the update fails.
  Future<void> updateOccurrenceStatus(int id, String status) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/occurrences/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Failed to update occurrence status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update occurrence status: $e');
    }
  }

  /// Closes the HTTP client when the service is no longer needed.
  void dispose() {
    _client.close();
  }
}
