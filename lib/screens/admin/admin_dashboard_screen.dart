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
    final stats = adminProvider.dashboardStats;
    final userName = authProvider.user?.name ?? 'Admin';

    // If not admin, redirect to login
    if (!adminProvider.isAdmin) {
      Future.microtask(() => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).pushNamed(AdminNotificationsPanel.routeName);
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(userName),
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
              icon: Icons.payments,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AdminAnalyticsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ManageUsersScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Service Types'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ManageServiceTypesScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_repair_service),
            title: const Text('Services'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ManageServicesScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Time Slots'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ManageTimeSlotsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_online),
            title: const Text('Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ManageBookingsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Support Requests'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ManageSupportRequestsScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Reviews'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ViewReviewsScreen.routeName);
            },
          ),
        ],
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
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildQuickAccessCard(
              title: 'Add Service',
              icon: Icons.add_business,
              onTap: () {
                Navigator.pushNamed(context, ManageServicesScreen.routeName);
              },
            ),
            _buildQuickAccessCard(
              title: 'View Bookings',
              icon: Icons.calendar_today,
              onTap: () {
                Navigator.pushNamed(context, ManageBookingsScreen.routeName);
              },
            ),
            _buildQuickAccessCard(
              title: 'Manage Users',
              icon: Icons.people,
              onTap: () {
                Navigator.pushNamed(context, ManageUsersScreen.routeName);
              },
            ),
            _buildQuickAccessCard(
              title: 'Analytics',
              icon: Icons.analytics,
              onTap: () {
                Navigator.pushNamed(context, AdminAnalyticsScreen.routeName);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppConstants.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
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
                Navigator.pushNamed(context, ManageBookingsScreen.routeName);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        // Add your recent bookings list here
      ],
    );
  }
}
