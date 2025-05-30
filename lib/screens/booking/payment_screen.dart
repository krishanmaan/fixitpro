import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/services/payment_service.dart';
import 'package:fixitpro/screens/booking/booking_success_screen.dart';
import 'package:fixitpro/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fixitpro/models/service_model.dart' as service_models;

class PaymentScreen extends StatefulWidget {
  static const String routeName = '/payment';

  final BookingModel pendingBooking;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.pendingBooking,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  bool _isProcessing = false;
  String? _errorMessage;
  final PaymentService _paymentService = PaymentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing ? _buildProcessingUI() : _buildPaymentOptionsUI(),
    );
  }

  Widget _buildProcessingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppConstants.primaryColor),
          const SizedBox(height: 24),
          Text(
            'Processing payment...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please do not close this page',
            style: TextStyle(fontSize: 14, color: AppConstants.lightTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionsUI() {
    // Calculate the service charge (total - visit charge)
    final double visitCharge = widget.pendingBooking.visitCharge ?? 0.0;
    final double serviceCharge = widget.amount - visitCharge;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visit Charge Highlight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visit Charge Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pay ₹${visitCharge.toStringAsFixed(0)} now to confirm your booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Service charge will be collected after service completion',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Order Summary
          _buildOrderSummary(visitCharge, serviceCharge),

          const SizedBox(height: 24),

          // Payment Methods Section
          Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),

          const SizedBox(height: 16),

          // Payment Method Options
          _buildPaymentMethods(),

          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Pay Now Button
          CustomButton(
            text: 'Pay Visit Charge ₹${visitCharge.toStringAsFixed(0)}',
            onPressed: _processPayment,
            width: double.infinity,
          ),

          const SizedBox(height: 16),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your booking will be confirmed only after successful payment of the visit charge. The service charge of ₹${serviceCharge.toStringAsFixed(0)} will be collected after the service is completed.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 14,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double visitCharge, double serviceCharge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const Divider(height: 24),

          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  image:
                      widget.pendingBooking.serviceImage.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(
                              widget.pendingBooking.serviceImage,
                            ),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    widget.pendingBooking.serviceImage.isEmpty
                        ? const Icon(
                          Icons.home_repair_service,
                          color: AppConstants.primaryColor,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pendingBooking.serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Area: ${widget.pendingBooking.area.toStringAsFixed(1)} sq.ft',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _summaryRow(
            'Date',
            DateFormat('EEEE, MMMM d, yyyy').format(widget.pendingBooking.timeSlot.date),
          ),
          _summaryRow('Time', widget.pendingBooking.timeSlot.time),
          _summaryRow('Address', widget.pendingBooking.address.address),

          if (widget.pendingBooking.materialDesignName != null)
            _summaryRow('Material', widget.pendingBooking.materialDesignName!),

          const Divider(height: 24),

          // Payment visualization
          Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Breakdown',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${widget.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Visit charge section
                      Expanded(
                        flex: visitCharge.toInt(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.only(
                              bottomLeft: const Radius.circular(12),
                              bottomRight:
                                  serviceCharge <= 0
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '₹${visitCharge.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const Text(
                                'PAYING NOW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Service charge section
                      if (serviceCharge > 0)
                        Expanded(
                          flex: serviceCharge.toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₹${serviceCharge.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                                Text(
                                  'PAY LATER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Highlight the payment breakdown
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visit Charge',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pay now to confirm booking',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${visitCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Charge',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pay after service completion',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.lightTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${serviceCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppConstants.textColor,
                ),
              ),
              Text(
                '₹${widget.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),

          // Add a badge to highlight what's being paid now
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Paying now: ₹${visitCharge.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: AppConstants.lightTextColor,
                fontSize: 14,
              ),
            ),
          ),
          Flexible(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                color: AppConstants.textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children:
          PaymentMethod.values.map((method) {
            final methodName = PaymentService.paymentMethodNames[method]!;
            final methodIcon = PaymentService.paymentMethodIcons[method]!;

            return RadioListTile<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(methodIcon, color: AppConstants.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(methodName, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              activeColor: AppConstants.primaryColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      _selectedMethod == method
                          ? AppConstants.primaryColor
                          : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    try {
      // Determine if we're processing visit charge or full payment
      final hasVisitCharge =
          widget.pendingBooking.visitCharge != null &&
          widget.pendingBooking.visitCharge! > 0;
      final paymentAmount =
          hasVisitCharge ? widget.pendingBooking.visitCharge! : widget.amount;

      // First process payment
      final result = await _paymentService.processPayment(
        bookingId: widget.pendingBooking.id,
        amount: paymentAmount,
        method: _selectedMethod,
        userId: authProvider.user!.id,
      );

      if (result['success']) {
        // Payment successful, now create the booking
        final booking = await bookingProvider.createBooking(
          BookingModel(
            id: const Uuid().v4(),
            userId: authProvider.user!.id,
            serviceId: serviceProvider.selectedService!.id,
            serviceName: serviceProvider.selectedService!.title,
            serviceImage: serviceProvider.selectedService!.imageUrl,
            tierSelected: _convertTierType(serviceProvider.selectedTier),
            area: serviceProvider.area,
            totalPrice: serviceProvider.calculateTotalPrice(),
            status: BookingStatus.pending,
            address: bookingProvider.selectedAddress!,
            timeSlot: bookingProvider.selectedTimeSlot!,
            createdAt: DateTime.now(),
            materialDesignId: serviceProvider.selectedDesign?.id,
            materialDesignName: serviceProvider.selectedDesign?.name,
            materialPrice: serviceProvider.selectedDesign?.pricePerUnit,
            visitCharge: serviceProvider.getSelectedTierPricing()?.visitCharge,
          ),
        );

        if (booking) {
          // Show success message and navigate back
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          // Show error message
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookingProvider.error ?? 'Failed to create booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Payment failed
        setState(() {
          _isProcessing = false;
          _errorMessage =
              result['message'] ?? 'Payment failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  // Helper method to convert service TierType to booking TierType
  TierType _convertTierType(service_models.TierType serviceTier) {
    switch (serviceTier) {
      case service_models.TierType.basic:
        return TierType.basic;
      case service_models.TierType.standard:
        return TierType.standard;
      case service_models.TierType.premium:
        return TierType.premium;
      default:
        return TierType.basic;
    }
  }
}
