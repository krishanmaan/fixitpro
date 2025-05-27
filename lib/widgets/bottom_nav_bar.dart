import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/screens/booking/booking_history_screen.dart';
import 'package:fixitpro/screens/home/home_screen.dart';
import 'package:fixitpro/screens/user/profile_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8.0 : 16.0,
            vertical: 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.history,
                label: 'Bookings',
                isSelected: currentIndex == 0,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 1,
                isMiddle: true,
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.person,
                label: 'Profile',
                isSelected: currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    bool isMiddle = false,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    // Calculate sizes based on screen size
    final double iconSize =
        isMiddle
            ? (isSmallScreen ? 26.0 : 30.0)
            : (isSmallScreen ? 22.0 : 24.0);

    final double fontSize = isSmallScreen ? 11.0 : 12.0;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == currentIndex) return;

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(
                context,
                BookingHistoryScreen.routeName,
              );
              break;
            case 1:
              Navigator.pushReplacementNamed(context, HomeScreen.routeName);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, ProfileScreen.routeName);
              break;
          }
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isMiddle ? 12.0 : 8.0,
            horizontal: 4.0,
          ),
          decoration:
              isSelected
                  ? BoxDecoration(
                    color:
                        isMiddle
                            ? AppConstants.primaryColor
                            : AppConstants.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  )
                  : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? (isMiddle ? Colors.white : AppConstants.primaryColor)
                        : Colors.grey.shade600,
                size: iconSize,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected
                          ? (isMiddle
                              ? Colors.white
                              : AppConstants.primaryColor)
                          : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
