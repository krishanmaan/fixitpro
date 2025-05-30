import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/screens/booking/booking_detail_screen.dart';
import 'package:fixitpro/screens/booking/reschedule_screen.dart';
import 'package:fixitpro/screens/booking/add_review_screen.dart';
import 'package:fixitpro/widgets/booking_card.dart';

import 'package:fixitpro/widgets/bottom_nav_bar.dart';

class BookingHistoryScreen extends StatefulWidget {
  static const String routeName = '/booking-history';

  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      if (authProvider.user == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please sign in to view bookings';
        });
        return;
      }

      // Load all bookings instead of just user bookings
      await bookingProvider.loadAllBookings();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading bookings: ${e.toString()}';
      });
      debugPrint('Error in _loadBookings: $e');
    }
  }

  void _navigateToBookingDetail(BookingModel booking) {
    Navigator.pushNamed(
      context,
      BookingDetailScreen.routeName,
      arguments: booking,
    );
  }

  void _rescheduleBooking(BookingModel booking) {
    if (booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed) {
      debugPrint("Navigating to reschedule screen with booking: ${booking.id}");
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => RescheduleScreen(),
              settings: RouteSettings(arguments: booking),
            ),
          )
          .then((_) {
            // Refresh the list when returning from reschedule screen
            setState(() {
              _isLoading = true;
            });

            _loadBookings();
          });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only pending or confirmed bookings can be rescheduled',
          ),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _navigateToAddReview(BookingModel booking) {
    if (booking.status == BookingStatus.completed) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => AddReviewScreen(bookingId: booking.id),
            ),
          )
          .then((_) {
            // Refresh the list when returning from add review screen
            setState(() {
              _isLoading = true;
            });

            _loadBookings();
          });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only completed bookings can be reviewed'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final userBookings = bookingProvider.allBookings;

    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: Column(
        children: [
          // Error message
          if (_error != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                style: const TextStyle(color: AppConstants.errorColor),
                textAlign: TextAlign.center,
              ),
            ),

          // Tab Bar
          Container(
            color: AppConstants.primaryColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppConstants.whiteColor,
              unselectedLabelColor: AppConstants.whiteColor.withAlpha(
                179,
              ), // 0.7 * 255 = ~179
              indicatorColor: AppConstants.whiteColor,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Confirmed'),
                Tab(text: 'In Progress'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // All Bookings Tab
                          _buildBookingsList(userBookings),

                          // Pending Tab
                          _buildBookingsList(
                            bookingProvider.getBookingsByStatus(
                              BookingStatus.pending,
                            ),
                          ),

                          // Confirmed Tab
                          _buildBookingsList(
                            bookingProvider.getBookingsByStatus(
                              BookingStatus.confirmed,
                            ),
                          ),

                          // In Progress Tab
                          _buildBookingsList(
                            bookingProvider.getBookingsByStatus(
                              BookingStatus.inProgress,
                            ),
                          ),

                          // Completed Tab
                          _buildBookingsList(
                            bookingProvider.getBookingsByStatus(
                              BookingStatus.completed,
                            ),
                          ),

                          // Cancelled Tab
                          _buildBookingsList(
                            bookingProvider.getBookingsByStatus(
                              BookingStatus.cancelled,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppConstants.lightTextColor.withAlpha(
                128,
              ), // 0.5 * 255 = ~128
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book a service to see it here',
              style: TextStyle(color: AppConstants.lightTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onTap: () => _navigateToBookingDetail(booking),
          onCancel:
              booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.confirmed
                  ? () => _showCancelDialog(booking)
                  : null,
          onReschedule:
              booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.confirmed
                  ? () => _rescheduleBooking(booking)
                  : null,
          onReview:
              booking.status == BookingStatus.completed &&
                      booking.reviewId == null
                  ? () => _navigateToAddReview(booking)
                  : null,
        );
      },
    );
  }

  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: const Text(
              'Are you sure you want to cancel this booking?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBooking(booking);
                },
                child: const Text(
                  'Yes, Cancel',
                  style: TextStyle(color: AppConstants.errorColor),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    try {
      setState(() {
        _isLoading = true;
      });

      await bookingProvider.cancelBooking(booking.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
