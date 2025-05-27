import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class RescheduleScreen extends StatefulWidget {
  static const String routeName = '/reschedule';

  const RescheduleScreen({super.key});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  final DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedTimeSlot;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimeSlots();
    });
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _isLoading = true;
      _selectedTimeSlot = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );
      await bookingProvider.loadAvailableTimeSlots(_selectedDate);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectTimeSlot(TimeSlot slot) {
    setState(() {
      _selectedTimeSlot = slot;
    });
  }

  Future<void> _rescheduleBooking(BookingModel booking) async {
    if (_selectedTimeSlot == null) {
      setState(() {
        _errorMessage = 'Please select a time slot';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      await bookingProvider.rescheduleBooking(booking.id, _selectedTimeSlot!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rescheduled successfully'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingModel;
    final bookingProvider = Provider.of<BookingProvider>(context);
    final availableSlots = bookingProvider.availableSlots;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateFormatter = DateFormat('EEEE, MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Booking'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Booking Info
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: AppConstants.backgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppConstants.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormatter.format(booking.timeSlot.date),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppConstants.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              booking.timeSlot.time,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: AppConstants.errorColor,
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppConstants.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppConstants.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Next day message
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                      border: Border.all(
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your booking will be rescheduled for tomorrow (${dateFormatter.format(tomorrow)})',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // New Time Slot Selection
                  const Text(
                    'Select New Time Slot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (availableSlots.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'No time slots available for tomorrow.\nPlease try again later or contact support.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppConstants.lightTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          availableSlots.map((slot) {
                            bool isAvailable =
                                slot.status == SlotStatus.available;
                            bool isSelected = _selectedTimeSlot?.id == slot.id;

                            return GestureDetector(
                              onTap:
                                  isAvailable
                                      ? () => _selectTimeSlot(slot)
                                      : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppConstants.primaryColor
                                          : isAvailable
                                          ? AppConstants.whiteColor
                                          : AppConstants.dividerColor,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.buttonBorderRadius,
                                  ),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppConstants.primaryColor
                                            : isAvailable
                                            ? AppConstants.dividerColor
                                            : AppConstants.dividerColor,
                                  ),
                                ),
                                child: Text(
                                  slot.time,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? AppConstants.whiteColor
                                            : isAvailable
                                            ? AppConstants.textColor
                                            : AppConstants.lightTextColor,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: const BoxDecoration(
              color: AppConstants.whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomOutlinedButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Reschedule',
                    onPressed:
                        _selectedTimeSlot != null
                            ? () => _rescheduleBooking(booking)
                            : null,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
