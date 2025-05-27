import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminNotificationsPanel extends StatefulWidget {
  static const String routeName = '/admin/notifications';

  const AdminNotificationsPanel({super.key});

  @override
  State<AdminNotificationsPanel> createState() =>
      _AdminNotificationsPanelState();
}

class _AdminNotificationsPanelState extends State<AdminNotificationsPanel> {
  final bool _isLoading = false;
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New Booking',
      'message': 'John Doe booked an AC Repair service',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'read': false,
      'type': 'booking',
    },
    {
      'id': '2',
      'title': 'Booking Cancelled',
      'message': 'Alice Smith cancelled her Plumbing Service booking',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'read': false,
      'type': 'cancellation',
    },
    {
      'id': '3',
      'title': 'New Review',
      'message':
          'Robert Johnson left a 5-star review for Electrical Repair service',
      'date': DateTime.now().subtract(const Duration(hours: 8)),
      'read': true,
      'type': 'review',
    },
    {
      'id': '4',
      'title': 'Payment Received',
      'message': 'Payment received for Booking #12345 - ₹1,500',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
      'type': 'payment',
    },
    {
      'id': '5',
      'title': 'New User Registration',
      'message': 'Emily Wilson created a new account',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
      'type': 'user',
    },
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere(
        (notification) => notification['id'] == id,
      );
      if (index != -1) {
        _notifications[index]['read'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'markAll') {
                  _markAllAsRead();
                } else if (value == 'clearAll') {
                  _clearAll();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'markAll',
                      child: Text('Mark all as read'),
                    ),
                    const PopupMenuItem(
                      value: 'clearAll',
                      child: Text('Clear all notifications'),
                    ),
                  ],
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue.withAlpha(26),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'You have $unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _markAllAsRead,
                            child: const Text('Mark all as read'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final formattedDate = dateFormat.format(notification['date']);
    final isRead = notification['read'] as bool;

    // Choose icon based on notification type
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'booking':
        icon = Icons.book_online;
        iconColor = Colors.blue;
        break;
      case 'cancellation':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'review':
        icon = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'user':
        icon = Icons.person_add;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notification['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification dismissed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withAlpha(51),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message']),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        tileColor: isRead ? null : Colors.blue.withAlpha(13),
        trailing:
            !isRead
                ? IconButton(
                  icon: const Icon(Icons.circle, size: 12, color: Colors.blue),
                  onPressed: () => _markAsRead(notification['id']),
                )
                : null,
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }

          // Show notification details
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(notification['title']),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(notification['message']),
                      const SizedBox(height: 16),
                      Text(
                        'Time: $formattedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}
