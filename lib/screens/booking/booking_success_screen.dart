import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/screens/booking/booking_detail_screen.dart';
import 'package:fixitpro/screens/home/home_screen.dart';
import 'package:fixitpro/screens/booking/booking_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class BookingSuccessScreen extends StatefulWidget {
  static const String routeName = '/booking-success';

  final BookingModel booking;
  final bool isLocalBooking;

  const BookingSuccessScreen({
    super.key,
    required this.booking,
    this.isLocalBooking = false,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showCopiedMessage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to launch WhatsApp with pre-filled message
  Future<void> _sendWhatsAppConfirmation(BuildContext context) async {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final formattedDate = dateFormat.format(widget.booking.timeSlot.date);
    final visitCharge = widget.booking.visitCharge ?? 0.0;
    final serviceCharge = widget.booking.totalPrice - visitCharge;

    final message = '''
🎉 *Booking Confirmation* 🎉

Thank you for booking with FixItPro!

*Booking Details:*
Service: ${widget.booking.serviceName}
Date: $formattedDate
Time: ${widget.booking.timeSlot.time}
Location: ${widget.booking.address.address}

*Payment Details:*
Visit Charge: ₹${visitCharge.toStringAsFixed(0)} (PAID)
Service Charge: ₹${serviceCharge.toStringAsFixed(0)} (Due at service completion)
Total: ₹${widget.booking.totalPrice.toStringAsFixed(0)}

Our technician will arrive at your location as scheduled. You can track or manage your booking through the app.

Thank you for choosing FixItPro! 🔧
''';

    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=+91XXXXXXXXXX&text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed on your device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyBookingIdToClipboard() {
    final bookingId = widget.booking.id.substring(0, 8);
    Clipboard.setData(ClipboardData(text: bookingId));

    setState(() {
      _showCopiedMessage = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCopiedMessage = false;
        });
      }
    });
  }

  void _navigateToBookingDetails() {
    Navigator.pushNamed(
      context,
      BookingDetailScreen.routeName,
      arguments: widget.booking,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Booking status chip
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(int.parse(_getStatusColor(widget.booking.status).substring(1), radix: 16) | 0xFF000000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.booking.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse(_getStatusColor(widget.booking.status).substring(1), radix: 16) | 0xFF000000),
                  ),
                ),
              ),

              // Payment success banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visit Charge Payment Successful',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Visit charge of ₹${widget.booking.visitCharge?.toStringAsFixed(0) ?? "0"} has been paid successfully',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Animated success icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppConstants.primaryColor,
                    size: 100,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Success message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your booking has been confirmed. We will send you a confirmation email shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Booking details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Booking ID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: _copyBookingIdToClipboard,
                          child: Row(
                            children: [
                              Text(
                                widget.booking.id.substring(0, 8),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy,
                                size: 16,
                                color: AppConstants.primaryColor,
                              ),
                              if (_showCopiedMessage)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Copied!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow('Service', widget.booking.serviceName),
                    _buildInfoRow(
                      'Date',
                      DateFormat(
                        'MMMM d, yyyy',
                      ).format(widget.booking.timeSlot.date),
                    ),
                    _buildInfoRow('Time', widget.booking.timeSlot.time),
                    _buildInfoRow('Address', widget.booking.address.address),
                    const Divider(height: 32),
                    _buildInfoRow(
                      'Visit Charge (Paid)',
                      '₹${widget.booking.visitCharge?.toStringAsFixed(0) ?? "0"}',
                    ),
                    _buildInfoRow(
                      'Service Charge (Due)',
                      '₹${(widget.booking.totalPrice - (widget.booking.visitCharge ?? 0.0)).toStringAsFixed(0)}',
                    ),
                    _buildInfoRow(
                      'Total',
                      '₹${widget.booking.totalPrice.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendWhatsAppConfirmation(context),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share on WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _navigateToBookingDetails,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppConstants.primaryColor,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          HomeScreen.routeName,
                          (route) => false,
                        );
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          BookingHistoryScreen.routeName,
                          (route) =>
                              route.settings.name == HomeScreen.routeName,
                        );
                      },
                      child: const Text('View All Bookings'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return '#FFA000'; // Amber
      case BookingStatus.confirmed:
        return '#4CAF50'; // Green
      case BookingStatus.inProgress:
        return '#2196F3'; // Blue
      case BookingStatus.completed:
        return '#4CAF50'; // Green
      case BookingStatus.cancelled:
        return '#F44336'; // Red
      case BookingStatus.rescheduled:
        return '#9C27B0'; // Purple
    }
  }
}
