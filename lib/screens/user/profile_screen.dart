import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/screens/auth/login_screen.dart';
import 'package:fixitpro/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Get screen size for responsive layout
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    // Calculate responsive sizes
    final double avatarRadius = isSmallScreen ? 50.0 : 60.0;
    final double iconSize = isSmallScreen ? 70.0 : 80.0;
    final double editIconSize = isSmallScreen ? 18.0 : 20.0;
    final double sectionSpacing = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body:
          user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: AppConstants.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile image and edit button
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: AppConstants.primaryColor.withAlpha(
                            26,
                          ),
                          child: Icon(
                            Icons.person,
                            size: iconSize,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Show image picker dialog
                                _showImagePickerDialog(context);
                              },
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: editIconSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // User name
                    Text(
                      user.name,
                      style: AppConstants.getResponsiveHeadingStyle(context),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // User email
                    Text(
                      user.email,
                      style: AppConstants.getResponsiveSmallTextStyle(context),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // User phone
                    Text(
                      user.phone ?? 'No phone number',
                      style: AppConstants.getResponsiveSmallTextStyle(context),
                    ),
                    SizedBox(height: sectionSpacing),

                    // Divider
                    const Divider(),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      "Account Settings",
                      style: AppConstants.getResponsiveSubheadingStyle(context),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // Profile options
                    _buildProfileOption(
                      context,
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        _navigateToEditProfile(context);
                      },
                    ),

                    _buildProfileOption(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'My Addresses',
                      subtitle: 'Manage your saved addresses',
                      onTap: () {
                        _navigateToAddresses(context);
                      },
                    ),

                    _buildProfileOption(
                      context,
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage your payment options',
                      onTap: () {
                        _navigateToPaymentMethods(context);
                      },
                    ),

                    // Divider
                    const Divider(),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      "App Settings",
                      style: AppConstants.getResponsiveSubheadingStyle(context),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),

                    _buildProfileOption(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Configure push notifications',
                      onTap: () {
                        _navigateToNotifications(context);
                      },
                    ),

                    _buildProfileOption(
                      context,
                      icon: Icons.color_lens_outlined,
                      title: 'Appearance',
                      subtitle: 'Change app theme and display settings',
                      onTap: () {
                        _showThemeDialog(context);
                      },
                    ),

                    _buildProfileOption(
                      context,
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'Change app language',
                      onTap: () {
                        _showLanguageDialog(context);
                      },
                    ),

                    // Support section
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Support",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildProfileOption(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with your account',
                      onTap: () {
                        _navigateToHelp(context);
                      },
                    ),

                    _buildProfileOption(
                      context,
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Learn more about FixItPro',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),

                    // Divider
                    const Divider(),
                    const SizedBox(height: 16),

                    // Logout button
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(
                                    'Logout Confirmation',
                                    style: TextStyle(
                                      fontSize:
                                          AppConstants.getResponsiveFontSize(
                                            context,
                                            18,
                                          ),
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(
                                      fontSize:
                                          AppConstants.getResponsiveFontSize(
                                            context,
                                            16,
                                          ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        authProvider.signOut();
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          LoginScreen.routeName,
                                          (route) => false,
                                        );
                                      },
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: AppConstants.getResponsiveFontSize(context, 22),
                        ),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: AppConstants.getResponsiveFontSize(
                              context,
                              16,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withAlpha(26),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    // Get responsive font sizes
    final double titleSize = AppConstants.getResponsiveFontSize(context, 16);
    final double subtitleSize = AppConstants.getResponsiveFontSize(context, 12);
    final double iconSize = AppConstants.getResponsiveFontSize(context, 22);

    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor, size: iconSize),
      title: Text(
        title,
        style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: AppConstants.lightTextColor,
                ),
              )
              : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppConstants.getResponsivePadding(context).left,
        vertical: 4,
      ),
      dense: MediaQuery.of(context).size.width < 360,
    );
  }

  // Navigate to Edit Profile screen
  void _navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, '/edit-profile');
  }

  // Navigate to Addresses screen
  void _navigateToAddresses(BuildContext context) {
    Navigator.pushNamed(context, '/addresses');
  }

  // Navigate to Payment Methods screen
  void _navigateToPaymentMethods(BuildContext context) {
    Navigator.pushNamed(context, '/payment-methods');
  }

  // Navigate to Notifications settings
  void _navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/notifications');
  }

  // Navigate to Help screen
  void _navigateToHelp(BuildContext context) {
    Navigator.pushNamed(context, '/help-support');
  }

  // Show About Dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FixItPro',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withAlpha(51),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.handyman, color: AppConstants.primaryColor, size: 30),
      ),
      applicationLegalese: '© 2023 FixItPro Ltd. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'FixItPro is a home repair and maintenance service platform.',
        ),
        const SizedBox(height: 8),
        const Text('Contact: support@fixitpro.com'),
      ],
    );
  }

  // Show Theme Dialog
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption(context, 'Light', Icons.light_mode),
                _buildThemeOption(context, 'Dark', Icons.dark_mode),
                _buildThemeOption(
                  context,
                  'System',
                  Icons.settings_system_daydream,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Build Theme Option
  Widget _buildThemeOption(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title theme selected')));
      },
    );
  }

  // Show Language Dialog
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(context, 'English', 'en'),
                _buildLanguageOption(context, 'Hindi', 'hi'),
                _buildLanguageOption(context, 'Spanish', 'es'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Build Language Option
  Widget _buildLanguageOption(BuildContext context, String title, String code) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title selected')));
      },
    );
  }

  // Show Image Picker Dialog
  void _showImagePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement camera functionality
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement gallery functionality
                  },
                ),
              ],
            ),
          ),
    );
  }
}
