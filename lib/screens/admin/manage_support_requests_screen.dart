import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitpro/constants/app_constants.dart';

import 'package:fixitpro/models/user_model.dart';
import 'package:intl/intl.dart';

class SupportRequest {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;
  String? response;
  DateTime? respondedAt;

  SupportRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.response,
    this.respondedAt,
  });

  factory SupportRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SupportRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? 'No email provided',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'new',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      response: data['response'],
      respondedAt:
          data['respondedAt'] != null
              ? (data['respondedAt'] as Timestamp).toDate()
              : null,
    );
  }
}

class ManageSupportRequestsScreen extends StatefulWidget {
  static const String routeName = '/admin/support-requests';

  const ManageSupportRequestsScreen({super.key});

  @override
  State<ManageSupportRequestsScreen> createState() =>
      _ManageSupportRequestsScreenState();
}

class _ManageSupportRequestsScreenState
    extends State<ManageSupportRequestsScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<SupportRequest> _supportRequests = [];
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _adminResponseController =
      TextEditingController();

  // Contact information controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSupportRequests();

    // Load admin contact information
    _loadAdminContactInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _adminResponseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminContactInfo() async {
    try {
      final docSnapshot =
          await _firestore.collection('app_settings').doc('contact_info').get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      } else {
        // Create default contact info if it doesn't exist
        await _firestore.collection('app_settings').doc('contact_info').set({
          'phone': '+1 800 FIX-ITPRO',
          'email': 'support@fixitpro.com',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _phoneController.text = '+1 800 FIX-ITPRO';
        _emailController.text = 'support@fixitpro.com';
      }
    } catch (e) {
      debugPrint('Error loading admin contact info: $e');
    }
  }

  Future<void> _saveContactInfo() async {
    try {
      await _firestore.collection('app_settings').doc('contact_info').set({
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact information updated successfully'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving contact info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating contact information: $e')),
        );
      }
    }
  }

  Future<void> _loadSupportRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await _firestore
              .collection('support_requests')
              .orderBy('createdAt', descending: true)
              .get();

      setState(() {
        _supportRequests =
            snapshot.docs
                .map((doc) => SupportRequest.fromFirestore(doc))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading support requests: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading support requests: $e')),
        );
      }
    }
  }

  Future<void> _updateSupportRequestStatus(
    String requestId,
    String status, [
    String? response,
  ]) async {
    try {
      final data = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (response != null) {
        data['response'] = response;
        data['respondedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('support_requests')
          .doc(requestId)
          .update(data);

      await _loadSupportRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Support request ${status == 'closed' ? 'closed' : 'updated'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating support request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating support request: $e')),
        );
      }
    }
  }

  Future<UserModel?> _getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromJson({...userData, 'id': userId});
      }
    } catch (e) {
      debugPrint('Error getting user details: $e');
    }
    return null;
  }

  List<SupportRequest> _getFilteredRequests() {
    final currentTab = _tabController.index;

    if (_searchQuery.isEmpty) {
      switch (currentTab) {
        case 0: // New
          return _supportRequests
              .where((request) => request.status == 'new')
              .toList();
        case 1: // In Progress
          return _supportRequests
              .where((request) => request.status == 'in_progress')
              .toList();
        case 2: // Closed
          return _supportRequests
              .where((request) => request.status == 'closed')
              .toList();
        default:
          return _supportRequests;
      }
    } else {
      // Apply search filter along with tab filter
      final searchLower = _searchQuery.toLowerCase();
      final filteredBySearch =
          _supportRequests.where((request) {
            return request.name.toLowerCase().contains(searchLower) ||
                request.email.toLowerCase().contains(searchLower) ||
                request.subject.toLowerCase().contains(searchLower) ||
                request.message.toLowerCase().contains(searchLower);
          }).toList();

      switch (currentTab) {
        case 0: // New
          return filteredBySearch
              .where((request) => request.status == 'new')
              .toList();
        case 1: // In Progress
          return filteredBySearch
              .where((request) => request.status == 'in_progress')
              .toList();
        case 2: // Closed
          return filteredBySearch
              .where((request) => request.status == 'closed')
              .toList();
        default:
          return filteredBySearch;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _getFilteredRequests();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _showContactSettingsDialog(),
            tooltip: 'Edit Contact Information',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupportRequests,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 3.0,
              color: AppConstants.primaryColor,
            ),
          ),
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'In Progress'),
            Tab(text: 'Closed'),
          ],
          onTap: (_) => setState(() {}), // Refresh UI when tab changes
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search support requests...',
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

                  // Support requests list
                  Expanded(
                    child:
                        filteredRequests.isEmpty
                            ? Center(
                              child: Text(
                                'No ${_tabController.index == 0
                                    ? 'new'
                                    : _tabController.index == 1
                                    ? 'in-progress'
                                    : 'closed'} support requests found',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredRequests.length,
                              itemBuilder: (context, index) {
                                final request = filteredRequests[index];
                                return _buildSupportRequestCard(request);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSupportRequestCard(SupportRequest request) {
    final dateFormat = DateFormat('MMM dd, yyyy, h:mm a');
    final formattedDate = dateFormat.format(request.createdAt);

    // Status colors
    Color statusColor;
    switch (request.status) {
      case 'new':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'closed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSupportRequestDetailsDialog(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        statusColor.r.toInt(),
                        statusColor.g.toInt(),
                        statusColor.b.toInt(),
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status == 'new'
                          ? 'New'
                          : request.status == 'in_progress'
                          ? 'In Progress'
                          : 'Closed',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(request.name, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.email,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.message,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted: $formattedDate',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (request.response != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Response:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        request.response!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (request.respondedAt != null)
                        Text(
                          'Responded: ${dateFormat.format(request.respondedAt!)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportRequestDetailsDialog(SupportRequest request) {
    final dateFormat = DateFormat('MMM dd, yyyy, h:mm a');
    _adminResponseController.text = request.response ?? '';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(request.subject),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              request.status == 'new'
                                  ? const Color(
                                    0x1A2196F3,
                                  ) // Colors.blue with opacity 0.1
                                  : request.status == 'in_progress'
                                  ? const Color(
                                    0x1AFF9800,
                                  ) // Colors.orange with opacity 0.1
                                  : const Color(
                                    0x1A4CAF50,
                                  ), // Colors.green with opacity 0.1
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          request.status == 'new'
                              ? 'New'
                              : request.status == 'in_progress'
                              ? 'In Progress'
                              : 'Closed',
                          style: TextStyle(
                            color:
                                request.status == 'new'
                                    ? Colors.blue
                                    : request.status == 'in_progress'
                                    ? Colors.orange
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // User details
                      FutureBuilder<UserModel?>(
                        future: _getUserDetails(request.userId),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'User Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow('Name', request.name),
                                _buildDetailRow('Email', request.email),
                                if (user != null && user.phone.isNotEmpty)
                                  _buildDetailRow('Phone', user.phone),
                                if (user != null)
                                  _buildDetailRow(
                                    'Admin',
                                    user.isAdmin ? 'Yes' : 'No',
                                  ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Message details
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Subject', request.subject),
                            _buildDetailRow(
                              'Date',
                              dateFormat.format(request.createdAt),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Message:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(request.message),
                            ),
                          ],
                        ),
                      ),

                      // Admin response
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Response',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (request.response != null &&
                                request.respondedAt != null)
                              _buildDetailRow(
                                'Responded',
                                dateFormat.format(request.respondedAt!),
                              ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _adminResponseController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Type your response here...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (request.status != 'closed')
                    TextButton(
                      onPressed: () {
                        final response = _adminResponseController.text.trim();
                        if (response.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please provide a response before closing',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop();
                        _updateSupportRequestStatus(
                          request.id,
                          'closed',
                          response,
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Close Request'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      final response = _adminResponseController.text.trim();
                      if (response.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide a response'),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop();
                      _updateSupportRequestStatus(
                        request.id,
                        request.status == 'new'
                            ? 'in_progress'
                            : request.status,
                        response,
                      );
                    },
                    child: const Text('Save Response'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showContactSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Contact Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Support Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Support Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_phoneController.text.trim().isEmpty ||
                      _emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  _saveContactInfo();
                },
                child: const Text('Save'),
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
}
