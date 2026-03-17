import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:patinhas_amor/models/animal.dart';

/// Service class responsible for handling all API communication
/// related to animals rescued by the NGO.
///
/// This service interacts with the REST API to create and fetch
/// animal records.
class AnimalService {
  /// Base URL for the API
  ///
  /// In a production environment, this should be configured
  /// through environment variables or a configuration file.
  static const String _baseUrl = 'http://10.0.2.2:3000';

  /// HTTP client for making API requests
  final http.Client _client;

  /// Creates an AnimalService instance.
  ///
  /// Optionally accepts a custom HTTP client for testing purposes.
  AnimalService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches all animals registered by the NGO.
  ///
  /// Returns a list of [Animal] objects.
  /// Throws an exception if the request fails.
  Future<List<Animal>> fetchAnimals() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/animals'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Animal.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load animals. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load animals: $e');
    }
  }

  /// Creates a new animal record in the system.
  ///
  /// [animal] is the animal data to be registered.
  /// Returns the created [Animal] with its assigned ID.
  /// Throws an exception if the creation fails.
  Future<Animal> createAnimal(Animal animal) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/animals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(animal.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Animal.fromJson(data);
      } else {
        throw Exception(
            'Failed to create animal. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create animal: $e');
    }
  }

  /// Closes the HTTP client when the service is no longer needed.
  void dispose() {
    _client.close();
  }
}
