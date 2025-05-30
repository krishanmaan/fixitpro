import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onReview;
  final bool isDetailView;

  const BookingCard({
    Key? key,
    required this.booking,
    required this.onTap,
    this.onCancel,
    this.onReschedule,
    this.onReview,
    this.isDetailView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor =
        AppConstants.bookingStatusColors[booking.status
            .toString()
            .split('.')
            .last] ??
        AppConstants.primaryColor;
    final statusLabel =
        AppConstants.bookingStatusLabels[booking.status
            .toString()
            .split('.')
            .last] ??
        'Unknown';
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCompletedBooking = booking.status == BookingStatus.completed;
    final hasReview = booking.reviewId != null;
    final hasValidBookingId = booking.id.isNotEmpty && booking.id.length >= 8;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.smallPadding,
          vertical: AppConstants.smallPadding,
        ),
        decoration: BoxDecoration(
          color: AppConstants.whiteColor,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26), // 0.1 * 255 = ~26
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.cardBorderRadius),
                  topRight: Radius.circular(AppConstants.cardBorderRadius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    hasValidBookingId
                        ? 'Booking #${booking.id.substring(0, 8)}'
                        : 'Booking',
                    style: TextStyle(
                      color: AppConstants.lightTextColor,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            // Booking Info
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User ID (added this to show which user made the booking)
                  if (booking.userId.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'User: ${booking.userId.substring(0, booking.userId.length > 10 ? 10 : booking.userId.length)}...',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Service name
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppConstants.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: _getServiceImage(booking.serviceImage),
                            fit: BoxFit.cover,
                            onError:
                                (_, __) =>
                                    const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.serviceName.isNotEmpty
                                  ? booking.serviceName
                                  : 'Service',
                              style: AppConstants.subheadingStyle.copyWith(
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tier: ${_getTierName(booking.tierSelected)}',
                              style: TextStyle(
                                color: AppConstants.lightTextColor,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Area & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoItem(
                        Icons.aspect_ratio,
                        '${booking.area.toStringAsFixed(1)} sq.ft',
                      ),
                      booking.visitCharge != null && booking.visitCharge! > 0
                          ? _paymentInfoItem(booking)
                          : _infoItem(
                            Icons.currency_rupee,
                            '₹${booking.totalPrice.toStringAsFixed(0)}',
                          ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Date & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoItem(
                        Icons.calendar_today,
                        dateFormat.format(booking.timeSlot.date),
                      ),
                      _infoItem(
                        Icons.access_time,
                        booking.timeSlot.time.isNotEmpty
                            ? booking.timeSlot.time
                            : 'Not specified',
                      ),
                    ],
                  ),

                  // Action buttons for regular view
                  if (!isDetailView &&
                      (booking.status == BookingStatus.pending ||
                          booking.status == BookingStatus.confirmed)) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (onReschedule != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              icon: const Icon(Icons.schedule, size: 16),
                              label: const Text('Reschedule'),
                              onPressed: onReschedule,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (onCancel != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppConstants.errorColor,
                                side: BorderSide(
                                  color: AppConstants.errorColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Cancel'),
                              onPressed: onCancel,
                            ),
                          ),
                      ],
                    ),
                  ],

                  if (isDetailView) ...[
                    const SizedBox(height: 12),

                    // Address
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address',
                          style: TextStyle(
                            color: AppConstants.lightTextColor,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppConstants.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${booking.address.label}: ${booking.address.address}',
                                style: TextStyle(
                                  color: AppConstants.textColor,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Booking date
                    Text(
                      'Booked on: ${DateFormat('MMM dd, yyyy hh:mm a').format(booking.createdAt)}',
                      style: TextStyle(
                        color: AppConstants.lightTextColor,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],

                  // Action buttons
                  if (isDetailView) ...[
                    const SizedBox(height: 24),

                    if (booking.status == BookingStatus.pending ||
                        booking.status == BookingStatus.confirmed) ...[
                      Row(
                        children: [
                          if (onReschedule != null)
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'Reschedule',
                                icon: Icons.schedule,
                                onPressed: onReschedule!,
                              ),
                            ),
                          const SizedBox(width: 12),
                          if (onCancel != null)
                            Expanded(
                              child: CustomOutlinedButton(
                                text: 'Cancel',
                                icon: Icons.cancel_outlined,
                                color: AppConstants.errorColor,
                                onPressed: onCancel!,
                              ),
                            ),
                        ],
                      ),
                    ],

                    if (isCompletedBooking &&
                        !hasReview &&
                        onReview != null) ...[
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Leave a Review',
                        icon: Icons.star_border,
                        onPressed: onReview!,
                      ),
                    ],

                    if (isCompletedBooking && hasReview) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(
                          AppConstants.smallPadding,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppConstants.accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'You have reviewed this service',
                              style: TextStyle(
                                color: AppConstants.accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textColor,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _paymentInfoItem(BookingModel booking) {
    final visitCharge = booking.visitCharge ?? 0.0;
    final serviceCharge = booking.totalPrice - visitCharge;
    final isServiceChargePaid =
        booking.serviceChargePaid || booking.status == BookingStatus.completed;

    return Row(
      children: [
        const Icon(
          Icons.payments_outlined,
          size: 18,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '₹${booking.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Visit: ',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppConstants.lightTextColor,
                  ),
                ),
                Text(
                  '₹${visitCharge.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PAID',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Service: ',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppConstants.lightTextColor,
                  ),
                ),
                Text(
                  '₹${serviceCharge.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isServiceChargePaid
                            ? Colors.green.shade700
                            : Colors.amber.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isServiceChargePaid
                            ? Colors.green.shade100
                            : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isServiceChargePaid ? 'PAID' : 'DUE',
                    style: TextStyle(
                      fontSize: 8,
                      color:
                          isServiceChargePaid
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _getTierName(TierType tier) {
    switch (tier) {
      case TierType.basic:
        return 'Basic';
      case TierType.standard:
        return 'Standard';
      case TierType.premium:
        return 'Premium';
      default:
        return 'Basic';
    }
  }

  // Helper to safely get service image
  ImageProvider _getServiceImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      try {
        return NetworkImage(imageUrl);
      } catch (e) {
        return const AssetImage('assets/images/placeholder.png');
      }
    } else {
      return const AssetImage('assets/images/placeholder.png');
    }
  }
}
