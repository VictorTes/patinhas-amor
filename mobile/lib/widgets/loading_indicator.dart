import 'package:flutter/material.dart';

/// Reusable loading indicator widget for the application.
///
/// Displays a centered circular progress indicator with optional text.
/// Use this widget when loading data from the API.
class LoadingIndicator extends StatelessWidget {
  /// Optional message to display below the loading spinner
  final String? message;

  /// Creates a LoadingIndicator widget.
  const LoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
