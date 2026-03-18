/// Constants used throughout the application.
///
/// This file contains centralized configuration values such as
/// API endpoints, timeout durations, and UI constants.
library;

/// API Configuration
class ApiConfig {
  /// Base URL for the REST API
  static const String baseUrl = 'http://localhost:3000';

  /// Request timeout duration in seconds
  static const int timeoutSeconds = 30;
}

/// Occurrence types used in the application
class OccurrenceTypes {
  static const String abandonment = 'abandonment';
  static const String abuse = 'abuse';
  static const String injured = 'injured';
}

/// UI Constants
class UIConstants {
  /// Standard padding used throughout the app
  static const double defaultPadding = 16.0;

  /// Small padding for compact spacing
  static const double smallPadding = 8.0;

  /// Large padding for section separation
  static const double largePadding = 24.0;

  /// Default border radius for cards and buttons
  static const double borderRadius = 12.0;

  /// Standard elevation for cards
  static const double cardElevation = 2.0;
}
