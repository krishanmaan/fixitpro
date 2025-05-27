import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/providers/admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBookingsScreen extends StatefulWidget {
  static const String routeName = '/admin/manage-bookings';

  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  final List<String> _tabs = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.fetchBookings();

    setState(() {
      _isLoading = false;
    });
  }

  // Method to get user details for a booking
  Future<Map<String, String>> _getUserDetails(String userId) async {
    // Create a cache for user details to avoid multiple Firestore calls
    if (_userDetailsCache.containsKey(userId)) {
      return _userDetailsCache[userId]!;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final details = {
          'name': data['name'] as String? ?? 'Unknown',
          'email': data['email'] as String? ?? 'No email',
          'phone': data['phone'] as String? ?? 'No phone',
        };

        // Cache the result
        _userDetailsCache[userId] = details;
        return details;
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }

    return {'name': 'User not found', 'email': 'No email', 'phone': 'No phone'};
  }

  // Cache for user details to avoid multiple Firestore calls
  final Map<String, Map<String, String>> _userDetailsCache = {};

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final bookings = adminProvider.bookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadBookings,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(bookings, null), // All bookings
                    _buildBookingsList(
                      bookings,
                      (booking) => booking.status == BookingStatus.pending,
                    ),
                    _buildBookingsList(
                      bookings,
                      (booking) => booking.status == BookingStatus.confirmed,
                    ),
                    _buildBookingsList(
                      bookings,
                      (booking) => booking.status == BookingStatus.completed,
                    ),
                    _buildBookingsList(
                      bookings,
                      (booking) => booking.status == BookingStatus.cancelled,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildBookingsList(
    List<BookingModel> bookings,
    bool Function(BookingModel)? filter,
  ) {
    final filteredBookings =
        filter != null ? bookings.where(filter).toList() : bookings;

    if (filteredBookings.isEmpty) {
      return const Center(
        child: Text('No bookings found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          'Booking #${booking.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.serviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Date: ${dateFormat.format(booking.timeSlot.date)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '₹${booking.totalPrice.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),

                // User Details
                FutureBuilder<Map<String, String>>(
                  future: _getUserDetails(booking.userId),
                  builder: (context, snapshot) {
                    final userName = snapshot.data?['name'] ?? 'Loading...';
                    final userEmail = snapshot.data?['email'] ?? 'Loading...';
                    final userPhone = snapshot.data?['phone'] ?? 'Loading...';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Email: $userEmail'),
                              Text('Phone: $userPhone'),
                            ],
                          ),
                        ),
                        if (userPhone != 'No phone' &&
                            userPhone != 'Loading...')
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () => _makePhoneCall(userPhone),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Booking Details
                const Text(
                  'Booking Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Service Type', booking.serviceName),
                _buildDetailRow('Unit Measurement', '${booking.area} sq.ft'),
                _buildDetailRow('Address', booking.address.address),
                if (booking.materialDesignName != null &&
                    booking.materialDesignName!.isNotEmpty)
                  _buildDetailRow(
                    'Material Design',
                    booking.materialDesignName!,
                  ),
                _buildDetailRow(
                  'Date & Time',
                  '${dateFormat.format(booking.timeSlot.date)} at ${booking.timeSlot.time}',
                ),
                _buildDetailRow(
                  'Booked on',
                  dateFormat.format(booking.createdAt),
                ),

                const SizedBox(height: 16),

                // Location link
                if (booking.address.latitude != 0 &&
                    booking.address.longitude != 0)
                  ElevatedButton.icon(
                    onPressed:
                        () => _openLocation(
                          booking.address.latitude,
                          booking.address.longitude,
                        ),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Open Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),

                const SizedBox(height: 16),

                // Actions based on status
                if (booking.status == BookingStatus.pending)
                  _buildActionButtons(
                    context,
                    booking.id,
                    BookingStatus.confirmed,
                    BookingStatus.cancelled,
                  ),
                if (booking.status == BookingStatus.confirmed)
                  _buildActionButtons(
                    context,
                    booking.id,
                    BookingStatus.inProgress,
                    BookingStatus.cancelled,
                  ),
                if (booking.status == BookingStatus.inProgress)
                  _buildActionButtons(
                    context,
                    booking.id,
                    BookingStatus.completed,
                    BookingStatus.cancelled,
                  ),
              ],
            ),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String bookingId,
    BookingStatus confirmStatus,
    BookingStatus cancelStatus,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => _updateBookingStatus(bookingId, confirmStatus),
          icon: Icon(_getActionIcon(confirmStatus)),
          label: Text(_getActionText(confirmStatus)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(confirmStatus),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _updateBookingStatus(bookingId, cancelStatus),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }

  Future<void> _updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    final success = await adminProvider.updateBookingStatus(bookingId, status);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking status updated successfully'
              : 'Failed to update booking status: ${adminProvider.error ?? "Unknown error"}',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _openLocation(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    await _launchUrl(url);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return AppConstants.primaryColor;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return AppConstants.successColor;
      case BookingStatus.cancelled:
        return AppConstants.errorColor;
      case BookingStatus.rescheduled:
        return Colors.blue;
    }
  }

  String _getActionText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirm';
      case BookingStatus.inProgress:
        return 'Start';
      case BookingStatus.completed:
        return 'Complete';
      case BookingStatus.cancelled:
        return 'Cancel';
      case BookingStatus.pending:
        return 'Process';
      case BookingStatus.rescheduled:
        return 'Reschedule';
    }
  }

  IconData _getActionIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.engineering;
      case BookingStatus.completed:
        return Icons.task_alt;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.pending:
        return Icons.pending_actions;
      case BookingStatus.rescheduled:
        return Icons.event_repeat;
    }
  }

  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone call to $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
