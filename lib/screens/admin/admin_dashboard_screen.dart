import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/providers/admin_provider.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/screens/admin/manage_bookings_screen.dart';
import 'package:fixitpro/screens/admin/manage_services_screen.dart';
import 'package:fixitpro/screens/admin/manage_service_types_screen.dart';
import 'package:fixitpro/screens/admin/manage_time_slots_screen.dart';
import 'package:fixitpro/screens/admin/manage_users_screen.dart';
import 'package:fixitpro/screens/admin/view_reviews_screen.dart';
import 'package:fixitpro/screens/admin/admin_analytics_screen.dart';
import 'package:fixitpro/screens/admin/admin_notifications_panel.dart';
import 'package:fixitpro/screens/admin/manage_support_requests_screen.dart';
import 'package:fixitpro/screens/auth/login_screen.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/admin/dashboard';

  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  final currencyFormatter = NumberFormat.currency(symbol: '₹');

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchDashboardStats();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final stats = adminProvider.stats;
    final currentAdmin = adminProvider.currentAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(AdminNotificationsPanel.routeName);
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(LoginScreen.routeName);
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(currentAdmin?.isSuperAdmin ?? false),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(currentAdmin?.name ?? 'Admin'),
                      const SizedBox(height: 24),
                      _buildStatisticsGrid(stats),
                      const SizedBox(height: 24),
                      _buildQuickAccessSection(),
                      const SizedBox(height: 24),
                      _buildRecentBookingsSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildWelcomeCard(String adminName) {
    return Card(
      color: AppConstants.primaryColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $adminName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Here\'s what\'s happening today',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Today: ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total Users',
              value: stats['userCount']?.toString() ?? '0',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Total Services',
              value: stats['serviceCount']?.toString() ?? '0',
              icon: Icons.home_repair_service,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Pending Bookings',
              value: stats['pendingBookings']?.toString() ?? '0',
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'Total Revenue',
              value: currencyFormatter.format(stats['totalRevenue'] ?? 0.0),
              icon: Icons.currency_rupee,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickAccessCard(
                title: 'Manage Services',
                icon: Icons.build,
                color: Colors.blue,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(ManageServicesScreen.routeName);
                },
              ),
              _buildQuickAccessCard(
                title: 'Service Types',
                icon: Icons.category,
                color: Colors.teal,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(ManageServiceTypesScreen.routeName);
                },
              ),
              _buildQuickAccessCard(
                title: 'Manage Bookings',
                icon: Icons.calendar_today,
                color: Colors.orange,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(ManageBookingsScreen.routeName);
                },
              ),
              _buildQuickAccessCard(
                title: 'Time Slots',
                icon: Icons.access_time,
                color: Colors.green,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(ManageTimeSlotsScreen.routeName);
                },
              ),
              _buildQuickAccessCard(
                title: 'View Reviews',
                icon: Icons.star,
                color: Colors.amber,
                onTap: () {
                  Navigator.of(context).pushNamed(ViewReviewsScreen.routeName);
                },
              ),
              _buildQuickAccessCard(
                title: 'Manage Users',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () {
                  Navigator.of(context).pushNamed(ManageUsersScreen.routeName);
                },
              ),
              _buildQuickAccessCard(
                title: 'Support Requests',
                icon: Icons.support_agent,
                color: Colors.teal,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(ManageSupportRequestsScreen.routeName);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  radius: 24,
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    // This would typically fetch recent bookings from your provider
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ManageBookingsScreen.routeName);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Recent bookings will appear here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminDrawer(bool isSuperAdmin) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppConstants.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isSuperAdmin ? 'Super Admin' : 'Admin',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_repair_service),
            title: const Text('Manage Services'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ManageServicesScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Service Types'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushNamed(ManageServiceTypesScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Manage Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ManageBookingsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Manage Time Slots'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ManageTimeSlotsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('View Reviews'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ViewReviewsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(ManageUsersScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Support Requests'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushNamed(ManageSupportRequestsScreen.routeName);
            },
          ),
          if (isSuperAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Manage Admins'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to admin management page
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AdminAnalyticsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(
                context,
              ).pushNamed(AdminNotificationsPanel.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              Navigator.pop(context);
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(LoginScreen.routeName);
              }
            },
          ),
        ],
      ),
    );
  }
}
