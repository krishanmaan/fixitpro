import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Firebase Crashlytics crash reporting
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Get the Crashlytics instance
  FirebaseCrashlytics get crashlytics => _crashlytics;

  /// Initialize the Crashlytics service
  Future<void> initialize() async {
    try {
      // Pass all uncaught errors from the framework to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
      };

      // For non-fatal errors (async errors that aren't caught by the Flutter framework)
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: false);
        return true;
      };
    } catch (e) {
      debugPrint('Error initializing Crashlytics: $e');
    }
  }

  /// Log a message to Crashlytics
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      debugPrint('Error logging to Crashlytics: $e');
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(error, stack, fatal: fatal);
    } catch (e) {
      debugPrint('Error recording error to Crashlytics: $e');
    }
  }

  /// Record a Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await _crashlytics.recordFlutterFatalError(details);
    } catch (e) {
      debugPrint('Error recording Flutter error to Crashlytics: $e');
    }
  }

  /// Set a custom key/value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Error setting custom key in Crashlytics: $e');
    }
  }

  /// Set user identifier
  Future<void> setUserIdentifier(String identifier) async {
    try {
      await _crashlytics.setUserIdentifier(identifier);
    } catch (e) {
      debugPrint('Error setting user identifier in Crashlytics: $e');
    }
  }

  /// Enable or disable collection of crash reports
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Error setting Crashlytics collection enabled: $e');
    }
  }

  /// Add multiple custom keys for crash reports
  Future<void> setCustomKeys(Map<String, dynamic> customKeys) async {
    try {
      for (final entry in customKeys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    } catch (e) {
      debugPrint('Error setting custom keys in Crashlytics: $e');
    }
  }

  /// Set crash attributes for the current user session
  Future<void> setUserAttributes({
    required String userId,
    String? userEmail,
    String? userRole,
  }) async {
    try {
      // Set user identifier
      await _crashlytics.setUserIdentifier(userId);

      // Set user attributes as custom keys
      if (userEmail != null) {
        await _crashlytics.setCustomKey('user_email', userEmail);
      }

      if (userRole != null) {
        await _crashlytics.setCustomKey('user_role', userRole);
      }
    } catch (e) {
      debugPrint('Error setting user attributes in Crashlytics: $e');
    }
  }

  /// Test a crash report (for development only)
  Future<void> testCrash() async {
    try {
      // Only allow test crashes in debug mode
      if (kDebugMode) {
        // Log that we're about to crash
        await _crashlytics.log('Testing crash functionality');

        // Force a crash
        throw Exception('This is a test crash');
      }
    } catch (e) {
      // This will be recorded by Crashlytics due to the error handlers
      rethrow;
    }
  }
}
