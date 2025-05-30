import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:fixitpro/providers/admin_provider.dart';
import 'package:intl/intl.dart';

class ManageUsersScreen extends StatefulWidget {
  static const String routeName = '/admin/manage-users';

  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchUsers();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final users = adminProvider.users;

    // Filter users based on search query
    final filteredUsers =
        _searchQuery.isEmpty
            ? users
            : users
                .where(
                  (user) =>
                      user.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      user.email.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUsers,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child:
                          filteredUsers.isEmpty
                              ? const Center(
                                child: Text(
                                  'No users found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return _buildUserCard(user);
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryColor.withAlpha(51),
          child: const Icon(Icons.person, color: AppConstants.primaryColor),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${user.email}'),
            if (user.phone.isNotEmpty) Text('Phone: ${user.phone}'),
            const SizedBox(height: 4),
            Text(
              'Joined: ${dateFormat.format(DateTime.now())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              children: [
                if (user.isAdmin)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing:
            !user.isAdmin
                ? IconButton(
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.indigo,
                  ),
                  tooltip: 'Promote to Admin',
                  onPressed: () => _showPromoteToAdminDialog(context, user),
                )
                : null,
        onTap: () => _showUserDetailsDialog(context, user),
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryColor.withAlpha(51),
                    child: const Icon(
                      Icons.person,
                      color: AppConstants.primaryColor,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Name', user.name),
                _buildDetailRow('Email', user.email),
                if (user.phone.isNotEmpty) _buildDetailRow('Phone', user.phone),
                _buildDetailRow('Joined', dateFormat.format(DateTime.now())),
                _buildDetailRow('User ID', user.id),
                _buildDetailRow('Admin', user.isAdmin ? 'Yes' : 'No'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (!user.isAdmin)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showPromoteToAdminDialog(context, user);
                  },
                  child: const Text('Promote to Admin'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showPromoteToAdminDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Promote to Admin'),
            content: Text(
              'Are you sure you want to promote ${user.name} to admin role?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _promoteToAdmin(user.id);
                },
                child: const Text('Promote'),
                style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              ),
            ],
          ),
    );
  }

  Future<void> _promoteToAdmin(String userId) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    final success = await adminProvider.promoteToAdmin(userId);

    // Refresh user list
    if (success) {
      await adminProvider.fetchUsers();
    }

    setState(() {
      _isLoading = false;
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'User promoted to admin successfully'
              : 'Failed to promote user: ${adminProvider.error ?? "Unknown error"}',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
