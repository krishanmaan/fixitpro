import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling in-app notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final String notificationId = _uuid.v4();
      final now = DateTime.now();

      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': now.toIso8601String(),
        'relatedId': relatedId,
        'additionalData': additionalData,
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Get all notifications for the current user
  Future<List<UserNotification>> getUserNotifications() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return [];
      }

      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                UserNotification.fromJson(doc.data()),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  /// Mark a notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for the current user
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return false;
      }

      // Get all unread notifications
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      // Use a batch to update all at once
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Create a booking confirmation notification
  Future<void> createBookingConfirmationNotification({
    required String userId,
    required String bookingId,
    required String serviceName,
    required DateTime bookingDate,
  }) async {
    final title = 'Booking Confirmed';
    final message =
        'Your booking for $serviceName on ${_formatDate(bookingDate)} has been confirmed.';

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'booking_confirmation',
      relatedId: bookingId,
      additionalData: {
        'bookingId': bookingId,
        'serviceName': serviceName,
        'bookingDate': bookingDate.toIso8601String(),
      },
    );
  }

  /// Create a booking reminder notification
  Future<void> createBookingReminderNotification({
    required String userId,
    required String bookingId,
    required String serviceName,
    required DateTime bookingDate,
  }) async {
    final title = 'Booking Reminder';
    final message =
        'Reminder: Your $serviceName service is scheduled for ${_formatDate(bookingDate)}.';

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'booking_reminder',
      relatedId: bookingId,
      additionalData: {
        'bookingId': bookingId,
        'serviceName': serviceName,
        'bookingDate': bookingDate.toIso8601String(),
      },
    );
  }

  /// Create a booking status update notification
  Future<void> createBookingStatusUpdateNotification({
    required String userId,
    required String bookingId,
    required String serviceName,
    required String status,
  }) async {
    final title = 'Booking Update';
    final message = 'Your booking for $serviceName has been $status.';

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'booking_status_update',
      relatedId: bookingId,
      additionalData: {
        'bookingId': bookingId,
        'serviceName': serviceName,
        'status': status,
      },
    );
  }

  /// Create a payment confirmation notification
  Future<void> createPaymentConfirmationNotification({
    required String userId,
    required String bookingId,
    required String serviceName,
    required double amount,
  }) async {
    final title = 'Payment Confirmed';
    final message =
        'Your payment of \$${amount.toStringAsFixed(2)} for $serviceName has been received.';

    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'payment_confirmation',
      relatedId: bookingId,
      additionalData: {
        'bookingId': bookingId,
        'serviceName': serviceName,
        'amount': amount,
      },
    );
  }

  /// Get notification settings for the current user
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return NotificationSettings(
        enablePush: prefs.getBool('notification_push') ?? true,
        enableEmail: prefs.getBool('notification_email') ?? true,
        enableBookingReminders:
            prefs.getBool('notification_booking_reminders') ?? true,
        enablePromotions: prefs.getBool('notification_promotions') ?? true,
      );
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return NotificationSettings();
    }
  }

  /// Save notification settings for the current user
  Future<bool> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notification_push', settings.enablePush);
      await prefs.setBool('notification_email', settings.enableEmail);
      await prefs.setBool(
        'notification_booking_reminders',
        settings.enableBookingReminders,
      );
      await prefs.setBool('notification_promotions', settings.enablePromotions);

      return true;
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      return false;
    }
  }

  /// Helper method to format a date for notifications
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Model for a user notification
class UserNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId;
  final Map<String, dynamic>? additionalData;

  UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
    this.additionalData,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      relatedId: json['relatedId'],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'relatedId': relatedId,
      'additionalData': additionalData,
    };
  }
}

/// Model for notification settings
class NotificationSettings {
  final bool enablePush;
  final bool enableEmail;
  final bool enableBookingReminders;
  final bool enablePromotions;

  NotificationSettings({
    this.enablePush = true,
    this.enableEmail = true,
    this.enableBookingReminders = true,
    this.enablePromotions = true,
  });

  NotificationSettings copyWith({
    bool? enablePush,
    bool? enableEmail,
    bool? enableBookingReminders,
    bool? enablePromotions,
  }) {
    return NotificationSettings(
      enablePush: enablePush ?? this.enablePush,
      enableEmail: enableEmail ?? this.enableEmail,
      enableBookingReminders:
          enableBookingReminders ?? this.enableBookingReminders,
      enablePromotions: enablePromotions ?? this.enablePromotions,
    );
  }
}
