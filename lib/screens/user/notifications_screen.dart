import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/widgets/custom_appbar.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<UserNotification> _notifications = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
        return;
      }

      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

      if (!mounted) return;

      setState(() {
        _notifications =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return UserNotification(
                id: doc.id,
                title: data['title'] as String? ?? 'Notification',
                message: data['message'] as String? ?? '',
                timestamp:
                    (data['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                isRead: data['isRead'] as bool? ?? false,
                type: data['type'] as String? ?? 'general',
                relatedId: data['relatedId'] as String?,
              );
            }).toList();

        // If no notifications found, add sample notifications
        if (_notifications.isEmpty) {
          _notifications = _getSampleNotifications();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
      // Add sample notifications in case of error
      setState(() {
        _notifications = _getSampleNotifications();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<UserNotification> _getSampleNotifications() {
    // Create sample notifications for first-time users
    return [
      UserNotification(
        id: '1',
        title: 'Welcome to FixItPro!',
        message:
            'Thank you for downloading our app. We\'re excited to help you with your home repair needs.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
        type: 'welcome',
      ),
      UserNotification(
        id: '2',
        title: 'New Service Available',
        message:
            'We\'ve added AC repair services to our offerings. Book now for special launch discounts!',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        type: 'promo',
      ),
      UserNotification(
        id: '3',
        title: 'Special Offer',
        message:
            'Get 20% off on your first booking. Use code WELCOME20 at checkout.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        type: 'promo',
      ),
    ];
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final unreadNotifications =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      setState(() {
        _notifications =
            _notifications.map((notification) {
              return notification.copyWith(isRead: true);
            }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notifications as read: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions:
            unreadCount > 0
                ? [
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    label: const Text(
                      'Mark all as read',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ]
                : null,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you of important updates',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _deleteNotification(notification.id);
          },
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: InkWell(
              onTap: () {
                _showNotificationDetails(context, notification);
                if (!notification.isRead) {
                  _markAsRead(notification.id);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color:
                          notification.isRead
                              ? Colors.transparent
                              : _getNotificationColor(notification.type),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getNotificationIcon(notification.type),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight:
                                          notification.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(notification.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color backgroundColor;

    switch (type) {
      case 'booking':
        iconData = Icons.calendar_today;
        backgroundColor = Colors.blue;
        break;
      case 'promo':
        iconData = Icons.local_offer;
        backgroundColor = Colors.orange;
        break;
      case 'payment':
        iconData = Icons.payment;
        backgroundColor = Colors.green;
        break;
      case 'welcome':
        iconData = Icons.waving_hand;
        backgroundColor = Colors.purple;
        break;
      case 'alert':
        iconData = Icons.warning;
        backgroundColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        backgroundColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha((0.1 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: backgroundColor, size: 24),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'promo':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'welcome':
        return Colors.purple;
      case 'alert':
        return Colors.red;
      default:
        return AppConstants.primaryColor;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    UserNotification notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _getNotificationIcon(notification.type),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Received on ${DateFormat('MMM d, yyyy • h:mm a').format(notification.timestamp)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      notification.message,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (notification.type == 'booking' &&
                    notification.relatedId != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to booking details
                        Navigator.pushNamed(
                          context,
                          '/booking-detail',
                          arguments: {'bookingId': notification.relatedId},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('View Booking Details'),
                    ),
                  ),
                if (notification.type == 'promo')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to services
                        Navigator.pushNamed(context, '/services-by-category');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Explore Services'),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}

class UserNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? relatedId;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'general',
    this.relatedId,
  });

  UserNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? relatedId,
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
    );
  }
}
