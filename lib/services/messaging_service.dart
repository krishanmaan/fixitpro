import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling Firebase Cloud Messaging (push notifications)
class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  // Local notifications plugin for handling foreground notifications
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Android notification channel
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Stream of messages received
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  // Get the FCM token
  Future<String?> get token => _messaging.getToken();

  /// Initialize the messaging service
  Future<void> initialize() async {
    try {
      // Request permission on iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications for foreground messages
      await _initializeLocalNotifications();

      // Get initial message if app was opened from a terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
        _messageStreamController.add(message);
      });

      // Handle messages when the app is in the background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Get FCM token and save it
      String? token = await _messaging.getToken();
      await _saveToken(token);
      debugPrint('FCM Token: $token');
    
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((String token) {
        _saveToken(token);
        debugPrint('FCM Token refreshed: $token');
      });
    } catch (e) {
      debugPrint('Error initializing messaging service: $e');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    // Initialize the plugin
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification taps
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload) as Map<String, dynamic>;
            final message = RemoteMessage(
              data: data,
              notification: RemoteNotification(
                title: data['title'] as String?,
                body: data['body'] as String?,
              ),
            );
            _handleMessage(message);
          } catch (e) {
            debugPrint('Error handling notification tap: $e');
          }
        }
      },
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Show a local notification for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon ?? 'ic_notification',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    // Add the message to the stream so it can be handled by listeners
    _messageStreamController.add(message);
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Save FCM token to shared preferences
  Future<void> _saveToken(String? token) async {
    try {
      if (token == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Get the saved FCM token
  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('Error getting saved FCM token: $e');
      return null;
    }
  }

  /// Clear FCM token (e.g. on logout)
  Future<void> clearToken() async {
    try {
      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }

  /// Get foreground notification options
  Future<void> setForegroundNotificationPresentationOptions() async {
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error setting foreground notification options: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}
