import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/screens/user/notifications_screen.dart';

class UserDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? additionalActions;

  const UserDashboardAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = AppConstants.isSmallScreen(context);

    // Calculate icon sizes based on screen size
    final double iconSize = isSmallScreen ? 20.0 : 24.0;
    final double avatarSize = isSmallScreen ? 36.0 : 40.0;

    return AppBar(
      title: title != null ? Text(title!) : null,
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
              : Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.handyman,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
      actions: [
        // Notification Icon
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, NotificationsScreen.routeName);
          },
          icon: Icon(Icons.notifications_outlined, size: iconSize),
        ),

        // Additional actions if provided
        if (additionalActions != null) ...additionalActions!,

        // User Avatar
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: Colors.grey.shade200,
            child: Icon(
              Icons.person,
              size: avatarSize / 2,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight);
  }
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color color;

  const NotificationBadge({
    super.key,
    required this.count,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child:
          count > 0
              ? Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
    );
  }
}
