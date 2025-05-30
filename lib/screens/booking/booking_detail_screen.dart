import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/screens/booking/add_review_screen.dart';
import 'package:fixitpro/screens/booking/reschedule_screen.dart';
import 'package:fixitpro/widgets/custom_button.dart';

import 'package:fixitpro/widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  static const String routeName = '/booking-detail';

  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingModel;
    final bookingProvider = Provider.of<BookingProvider>(context);

    // Check for updated booking (in case of status change)
    final updatedBooking =
        bookingProvider.getBookingById(booking.id) ?? booking;

    final isCompletedBooking = updatedBooking.status == BookingStatus.completed;
    final hasReview = updatedBooking.reviewId != null;
    final canCancel =
        updatedBooking.status == BookingStatus.pending ||
        updatedBooking.status == BookingStatus.confirmed;
    final canReschedule = canCancel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(updatedBooking),
                    const SizedBox(height: 20),

                    _buildSectionCard(
                      title: 'Service Information',
                      icon: Icons.home_repair_service,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppConstants.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image:
                                      updatedBooking.serviceImage.isNotEmpty
                                          ? NetworkImage(
                                                updatedBooking.serviceImage,
                                              )
                                              as ImageProvider
                                          : const AssetImage(
                                            'assets/images/placeholder.png',
                                          ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              updatedBooking.serviceName,
                              style: AppConstants.subheadingStyle,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tier: ${_getTierName(updatedBooking.tierSelected)}',
                                  style: const TextStyle(
                                    color: AppConstants.lightTextColor,
                                  ),
                                ),
                                Text(
                                  'Area: ${updatedBooking.area.toStringAsFixed(2)} sq.ft',
                                  style: const TextStyle(
                                    color: AppConstants.lightTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (updatedBooking.materialDesignId != null &&
                              updatedBooking.materialDesignName != null) ...[
                            const SizedBox(height: 16),
                            _buildDetailItem(
                              'Material',
                              updatedBooking.materialDesignName!,
                              Icons.design_services,
                            ),
                            if (updatedBooking.materialPrice != null) ...[
                              const SizedBox(height: 16),
                              _buildDetailItem(
                                'Material Cost',
                                '₹${updatedBooking.materialPrice!.toStringAsFixed(2)}',
                                Icons.monetization_on,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Schedule',
                      icon: Icons.event,
                      content: Column(
                        children: [
                          _buildDetailItem(
                            'Date',
                            DateFormat(
                              'EEEE, MMM dd, yyyy',
                            ).format(updatedBooking.timeSlot.date),
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailItem(
                            'Time',
                            updatedBooking.timeSlot.time,
                            Icons.access_time,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Address',
                      icon: Icons.location_on,
                      content: Column(
                        children: [
                          _buildDetailItem(
                            updatedBooking.address.label,
                            updatedBooking.address.address,
                            Icons.home,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      title: 'Payment Details',
                      icon: Icons.payment,
                      content: Column(
                        children: [
                          // Calculate service charge
                          Builder(
                            builder: (context) {
                              final visitCharge =
                                  updatedBooking.visitCharge ?? 0.0;
                              final serviceCharge =
                                  updatedBooking.totalPrice - visitCharge;

                              return Column(
                                children: [
                                  // Visit charge row with payment status
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Visit Charge:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${visitCharge.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.green.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              'PAID',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Service charge row with payment status
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Service Charge:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${serviceCharge.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  updatedBooking
                                                              .serviceChargePaid ||
                                                          updatedBooking
                                                                  .status ==
                                                              BookingStatus
                                                                  .completed
                                                      ? Colors.green.shade100
                                                      : Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    updatedBooking
                                                                .serviceChargePaid ||
                                                            updatedBooking
                                                                    .status ==
                                                                BookingStatus
                                                                    .completed
                                                        ? Colors.green.shade300
                                                        : Colors.amber.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              updatedBooking
                                                          .serviceChargePaid ||
                                                      updatedBooking.status ==
                                                          BookingStatus
                                                              .completed
                                                  ? 'PAID'
                                                  : 'DUE',
                                              style: TextStyle(
                                                color:
                                                    updatedBooking
                                                                .serviceChargePaid ||
                                                            updatedBooking
                                                                    .status ==
                                                                BookingStatus
                                                                    .completed
                                                        ? Colors.green.shade700
                                                        : Colors.amber.shade800,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Total row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Amount:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '₹${updatedBooking.totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Add payment note for service charge
                                  if (!updatedBooking.serviceChargePaid &&
                                      updatedBooking.status !=
                                          BookingStatus.completed &&
                                      updatedBooking.status !=
                                          BookingStatus.cancelled) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.blue.shade700,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Service charge will be collected after service completion.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (canCancel || canReschedule) ...[
                      const Text(
                        'Booking Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          if (canReschedule) ...[
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'Reschedule',
                                icon: Icons.schedule,
                                onPressed:
                                    () => _navigateToReschedule(updatedBooking),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (canCancel) ...[
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'Cancel Booking',
                                icon: Icons.cancel_outlined,
                                color: AppConstants.errorColor,
                                onPressed:
                                    () => _showCancelDialog(updatedBooking),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (isCompletedBooking && !hasReview) ...[
                      CustomButton(
                        text: 'Leave a Review',
                        icon: Icons.star_border,
                        onPressed: () => _navigateToAddReview(updatedBooking),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (hasReview) ...[
                      CustomButton(
                        text: 'View Review',
                        icon: Icons.star,
                        onPressed: () => _navigateToViewReview(updatedBooking),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatusCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Booking ID:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.lightTextColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                booking.id.substring(0, 8),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(booking.status),
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Booked on: ${DateFormat('MMM dd, yyyy').format(booking.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.lightTextColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.lightTextColor,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                  fontFamily: 'Poppins',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
    try {
      setState(() {
        _isLoading = true;
      });

      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      await bookingProvider.cancelBooking(booking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToReschedule(BookingModel booking) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RescheduleScreen(),
            settings: RouteSettings(arguments: booking),
          ),
        )
        .then((_) {
          // Refresh to get updated booking after returning
          if (!mounted) return;

          setState(() {
            _isLoading = true;
          });

          // Force refresh the booking provider
          final bookingProvider = Provider.of<BookingProvider>(
            context,
            listen: false,
          );
          bookingProvider.loadUserBookings().then((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
        });
  }

  void _navigateToAddReview(BookingModel booking) {
    if (booking.status == BookingStatus.completed) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => AddReviewScreen(),
              settings: RouteSettings(arguments: booking),
            ),
          )
          .then((_) {
            // Refresh to get updated booking after returning
            if (!mounted) return;

            setState(() {
              _isLoading = true;
            });

            // Force refresh the booking provider
            final bookingProvider = Provider.of<BookingProvider>(
              context,
              listen: false,
            );
            bookingProvider.loadUserBookings().then((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
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

  void _navigateToViewReview(BookingModel booking) {
    if (booking.reviewId != null) {
      _showReviewDialog(booking);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No review found for this booking'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
    }
  }

  void _showReviewDialog(BookingModel booking) {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => FutureBuilder(
            future: bookingProvider.getReviewDetails(booking.reviewId!),
            builder: (context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                  title: Text('Loading Review'),
                  content: Center(
                    heightFactor: 1,
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return AlertDialog(
                  title: const Text('Review Not Found'),
                  content: const Text(
                    'The review details could not be loaded.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final reviewData = snapshot.data!;
              final double rating = reviewData['rating'] ?? 0.0;
              final String comment =
                  reviewData['comment'] ?? 'No comment provided';
              final DateTime createdAt =
                  reviewData['createdAt'] ?? DateTime.now();

              return AlertDialog(
                title: const Text('Your Review'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : (index < rating
                                        ? Icons.star_half
                                        : Icons.star_border),
                                color: AppConstants.accentColor,
                                size: 20,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(comment, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Text(
                      'Reviewed on ${_formatDate(createdAt)}',
                      style: const TextStyle(
                        color: AppConstants.lightTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTierName(TierType tier) {
    switch (tier) {
      case TierType.basic:
        return 'Basic';
      case TierType.standard:
        return 'Standard';
      case TierType.premium:
        return 'Premium';
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

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.engineering;
      case BookingStatus.completed:
        return Icons.task_alt;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.rescheduled:
        return Icons.event_repeat;
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
}
