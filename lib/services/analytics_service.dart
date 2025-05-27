import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Firebase Analytics tracking
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Get the analytics instance
  FirebaseAnalytics get analytics => _analytics;

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  /// Log user sign up
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  /// Log user login
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  /// Log booking creation
  Future<void> logBookingCreated({
    required String bookingId,
    required String serviceId,
    required String serviceName,
    required double value,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_created',
        parameters: {
          'booking_id': bookingId,
          'service_id': serviceId,
          'service_name': serviceName,
          'booking_value': value,
        },
      );
    } catch (e) {
      debugPrint('Error logging booking creation: $e');
    }
  }

  /// Log booking canceled
  Future<void> logBookingCanceled({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_canceled',
        parameters: {'booking_id': bookingId, 'cancel_reason': reason},
      );
    } catch (e) {
      debugPrint('Error logging booking cancellation: $e');
    }
  }

  /// Log service search
  Future<void> logServiceSearch({required String searchTerm}) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
    } catch (e) {
      debugPrint('Error logging search: $e');
    }
  }

  /// Log payment
  Future<void> logPayment({
    required String bookingId,
    required String serviceId,
    required String paymentMethod,
    required double value,
  }) async {
    try {
      final List<AnalyticsEventItem> items = [
        AnalyticsEventItem(itemId: serviceId, itemName: 'Service Booking'),
      ];

      await _analytics.logPurchase(
        currency: 'INR',
        value: value,
        items: items,
        transactionId: bookingId,
        parameters: {'payment_method': paymentMethod},
      );
    } catch (e) {
      debugPrint('Error logging payment: $e');
    }
  }

  /// Log rating submission
  Future<void> logRatingSubmitted({
    required String bookingId,
    required String serviceId,
    required double rating,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'rating_submitted',
        parameters: {
          'booking_id': bookingId,
          'service_id': serviceId,
          'rating_value': rating,
        },
      );
    } catch (e) {
      debugPrint('Error logging rating submission: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    required String userId,
    String? userRole,
  }) async {
    try {
      await _analytics.setUserId(id: userId);

      if (userRole != null) {
        await _analytics.setUserProperty(name: 'user_role', value: userRole);
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }
}
