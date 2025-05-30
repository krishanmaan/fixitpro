import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart' as booking_models;
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/screens/booking/payment_screen.dart';
import 'package:fixitpro/widgets/custom_button.dart';
import 'package:fixitpro/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class BookingScreen extends StatefulWidget {
  static const String routeName = '/booking';

  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLabelController = TextEditingController();

  int _currentStep = 0;
  final double _area = 100.0; // Default area value
  double _totalPrice = 0;
  SavedAddress? _selectedAddress;
  booking_models.TimeSlot? _selectedTimeSlot;
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _shouldSaveAddress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize with service provider's area value if available
      final serviceProvider = Provider.of<ServiceProvider>(
        context,
        listen: false,
      );
      _calculatePrice();
      _loadTimeSlots();

      // Pre-fill user info if available
      _prefillUserInfo();
    });
  }

  void _prefillUserInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _nameController.text = user.name;
      if (user.phone.isNotEmpty ?? false) {
        _phoneController.text = user.phone;
      }

      // Pre-select saved address if available
      if (user.savedAddresses.isNotEmpty) {
        _selectAddress(user.savedAddresses.first);
      }
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeSlots() async {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await bookingProvider.loadAvailableTimeSlots(_selectedDate);
    } catch (e) {
      // If loading time slots fails (e.g., permission issues), generate local time slots
      debugPrint('Error loading time slots: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Generate local time slots as fallback when Firebase has permission issues
  List<booking_models.TimeSlot> _generateLocalTimeSlots(DateTime date) {
    final slots = <booking_models.TimeSlot>[];
    final now = DateTime.now();
    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final int currentHour = now.hour;

    // Morning slots (9 AM to 12 PM)
    for (int hour = 9; hour <= 12; hour++) {
      // Skip time slots in the past for today
      if (isToday && hour <= currentHour) continue;

      final String timeStr = '${hour.toString().padLeft(2, '0')}:00 AM';
      slots.add(_createLocalTimeSlot(date, timeStr));
    }

    // Afternoon slots (1 PM to 6 PM)
    for (int hour = 1; hour <= 6; hour++) {
      // Skip time slots in the past for today
      if (isToday && hour + 12 <= currentHour) continue;

      final String timeStr = '${hour.toString().padLeft(2, '0')}:00 PM';
      slots.add(_createLocalTimeSlot(date, timeStr));
    }

    return slots;
  }

  booking_models.TimeSlot _createLocalTimeSlot(DateTime date, String timeStr) {
    // Generate a deterministic ID based on date and time to ensure consistent selection
    final String id =
        '${date.year}${date.month}${date.day}-${timeStr.replaceAll(RegExp(r'[^0-9]'), '')}';

    return booking_models.TimeSlot(
      id: id,
      date: date,
      time: timeStr,
      status: booking_models.SlotStatus.available,
    );
  }

  void _calculatePrice() {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );

    setState(() {
      _totalPrice = serviceProvider.calculateTotalPrice();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: AppConstants.whiteColor,
              onSurface: AppConstants.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });

      _loadTimeSlots();
    }
  }

  void _selectTimeSlot(booking_models.TimeSlot slot) {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    // When calling this method from a build context, wrap in post-frame callback
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bookingProvider.selectTimeSlot(slot);
        setState(() {
          _selectedTimeSlot = slot;
        });
      });
    } else {
      // Normal execution when not called during build
      bookingProvider.selectTimeSlot(slot);
      setState(() {
        _selectedTimeSlot = slot;
      });
    }
  }

  void _selectAddress(SavedAddress address) {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    // Convert user_models.SavedAddress to booking_models.SavedAddress
    booking_models.SavedAddress bookingAddress = booking_models.SavedAddress(
      id: address.id,
      label: address.label,
      address: address.address,
      latitude: address.latitude,
      longitude: address.longitude,
    );

    bookingProvider.selectAddress(bookingAddress);
    setState(() {
      _selectedAddress = address;
      _addressController.text = address.address;
    });
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final serviceProvider = Provider.of<ServiceProvider>(
        context,
        listen: false,
      );
      final user = authProvider.user;
      final service = serviceProvider.selectedService;

      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'unauthenticated',
          message: 'Please sign in to book a service',
        );
      }

      if (service == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Selected service not found',
        );
      }

      if (_selectedTimeSlot == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Please select a time slot',
        );
      }

      // If no saved address is selected, create one from the entered address
      booking_models.SavedAddress bookingAddress;
      if (_selectedAddress != null) {
        bookingAddress = _convertToBookingAddress(_selectedAddress!);
      } else {
        // Create a new address from the text field
        String addressText = _addressController.text.trim();
        if (addressText.isEmpty) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'failed-precondition',
            message: 'Please enter a valid address',
          );
        }

        // Save this address to user profile for future use if checkbox is checked
        if (_shouldSaveAddress) {
          // Make sure we have a label
          String label = _addressLabelController.text.trim();
          if (label.isEmpty) {
            label = 'Booking Address';
          }

          // Save address to user profile
          _saveAddressToUserProfile(addressText, label);
        }

        bookingAddress = booking_models.SavedAddress(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label:
              _shouldSaveAddress
                  ? _addressLabelController.text.trim()
                  : 'Booking Address',
          address: addressText,
          latitude: 0.0, // Default values since we don't have geocoding
          longitude: 0.0,
        );
      }

      // Convert ServiceModel.TierType to booking_models.TierType
      booking_models.TierType bookingTier;
      switch (serviceProvider.selectedTier) {
        case TierType.basic:
          bookingTier = booking_models.TierType.basic;
          break;
        case TierType.standard:
          bookingTier = booking_models.TierType.standard;
          break;
        case TierType.premium:
          bookingTier = booking_models.TierType.premium;
          break;
      }

      // Get the selected tier visit charge
      final selectedTierPricing = serviceProvider.getSelectedTierPricing();
      final visitCharge = selectedTierPricing?.visitCharge ?? 0.0;

      // Create a pending booking model (not saved to database yet)
      final pendingBooking = booking_models.BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        userId: user.id,
        serviceId: service.id,
        serviceName: service.title,
        serviceImage: service.imageUrl,
        tierSelected: bookingTier,
        area: _area,
        totalPrice: _totalPrice,
        status: booking_models.BookingStatus.pending,
        address: bookingAddress,
        timeSlot: _selectedTimeSlot!,
        createdAt: DateTime.now(),
        materialDesignId: serviceProvider.selectedDesign?.id,
        materialDesignName: serviceProvider.selectedDesign?.name,
        materialPrice: serviceProvider.selectedDesign?.pricePerUnit,
        visitCharge: visitCharge, // Set the visit charge from selected tier
      );

      // Navigate to payment screen
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentScreen(
                  pendingBooking: pendingBooking,
                  amount: _totalPrice,
                ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = e.toString();
        }
        _isLoading = false;
      });

      // Show error dialog for better visibility
      if (mounted && _errorMessage != null) {
        _showErrorDialog(_errorMessage!);
      }
    }
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0: // Choose date & time
        return _selectedTimeSlot != null;
      case 1: // Enter address
        return _addressController.text.isNotEmpty;
      case 2: // Confirmation
        return true;
      default:
        return false;
    }
  }

  void _continue() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    } else if (_currentStep == 2) {
      _createBooking();
    }
  }

  void _cancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final service = serviceProvider.selectedService;
    // Removed unused selectedTier variable
    final user = authProvider.user;
    final timeSlots = bookingProvider.availableSlots;

    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Service')),
        body: const Center(child: Text('Please select a service first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${service.title}'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On very small screens, use vertical stepper
            final StepperType stepperType =
                constraints.maxWidth < 450
                    ? StepperType.vertical
                    : StepperType.horizontal;

            return Stepper(
              physics: const ClampingScrollPhysics(),
              type: stepperType,
              currentStep: _currentStep,
              onStepTapped: (step) {
                if (step < _currentStep) {
                  setState(() {
                    _currentStep = step;
                  });
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text:
                              _currentStep == 2
                                  ? 'Confirm Booking'
                                  : 'Continue',
                          onPressed: _canContinue() ? () => _continue() : null,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomOutlinedButton(
                          text: 'Back',
                          onPressed: () => _cancel(),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Select Date & Time
                Step(
                  title: const Text('Date & Time'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade300,
                                child:
                                    service.imageUrl.isNotEmpty
                                        ? Image.network(
                                          service.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.home_repair_service,
                                                    color: Colors.grey,
                                                  ),
                                        )
                                        : const Icon(
                                          Icons.home_repair_service,
                                          color: Colors.grey,
                                        ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Area: ${_area.round()} ${service.unit == MeasurementUnit.sqft ? 'sq.ft' : 'inches'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Price: ₹${_totalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Date selection
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, MMM d, yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppConstants.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time slot selection
                      const Text(
                        'Select Time Slot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (bookingProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (timeSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'No time slots available for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please select a different date or contact support for assistance.',
                                style: TextStyle(color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        // Use SingleChildScrollView to prevent overflow
                        SingleChildScrollView(
                          child: Wrap(
                            spacing: 8, // Reduced spacing
                            runSpacing: 8, // Reduced spacing
                            children:
                                timeSlots.map((slot) {
                                  final isSelected =
                                      _selectedTimeSlot?.id == slot.id;
                                  final isUnavailable =
                                      slot.status ==
                                      booking_models.SlotStatus.booked;
                                  return GestureDetector(
                                    onTap:
                                        isUnavailable
                                            ? null
                                            : () => _selectTimeSlot(slot),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12, // Reduced padding
                                        vertical: 8, // Reduced padding
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? AppConstants.primaryColor
                                                : isUnavailable
                                                ? Colors.red.shade50
                                                : Colors.white,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? AppConstants.primaryColor
                                                  : isUnavailable
                                                  ? Colors.red.shade300
                                                  : Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            slot.time,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : isUnavailable
                                                      ? Colors.red.shade800
                                                      : Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13, // Reduced font size
                                            ),
                                          ),
                                          if (isUnavailable) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              'BOOKED',
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                    ],
                  ),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),

                // Step 2: Address
                Step(
                  title: const Text('Address'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saved addresses
                      if (user != null && user.savedAddresses.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saved Addresses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _navigateToAddAddress,
                              icon: const Icon(
                                Icons.add_location_alt,
                                size: 18,
                              ),
                              label: const Text('Add New'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppConstants.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: user.savedAddresses.length,
                            itemBuilder: (context, index) {
                              final address = user.savedAddresses[index];
                              final isSelected =
                                  _selectedAddress?.id == address.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppConstants.primaryColor
                                            : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.location_on,
                                    color:
                                        isSelected
                                            ? AppConstants.primaryColor
                                            : Colors.grey,
                                  ),
                                  title: Text(
                                    address.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(address.address),
                                  onTap: () => _selectAddress(address),
                                  selected: isSelected,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Or Enter a New Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // If user has no saved addresses
                      if (user != null && user.savedAddresses.isEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'No saved addresses',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You can add and manage addresses for easy selection in future bookings.',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _navigateToAddAddress,
                                  icon: const Icon(Icons.add_location_alt),
                                  label: const Text('Add New Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // New address input
                      CustomTextField(
                        controller: _addressController,
                        label: 'Full Address',
                        hint: 'Enter your full address',
                        maxLines: 3,
                        validator: (value) {
                          if (_selectedAddress == null &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),

                      // Checkbox to save address
                      if (user != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _shouldSaveAddress,
                              onChanged: (value) {
                                setState(() {
                                  _shouldSaveAddress = value ?? false;
                                });
                              },
                              activeColor: AppConstants.primaryColor,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _shouldSaveAddress = !_shouldSaveAddress;
                                  });
                                },
                                child: const Text(
                                  'Save this address to my profile',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_shouldSaveAddress) ...[
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _addressLabelController,
                            label: 'Address Label',
                            hint: 'e.g., Home, Office, etc.',
                            validator:
                                _shouldSaveAddress
                                    ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a label for this address';
                                      }
                                      return null;
                                    }
                                    : null,
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),

                      // Name and phone fields - use column on small screens
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // If screen width is less than 600px, stack the fields vertically
                          if (constraints.maxWidth < 600) {
                            return Column(
                              children: [
                                CustomTextField(
                                  label: 'Your Name',
                                  hint: 'Enter your name',
                                  controller: _nameController,
                                  prefixIcon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Phone Number',
                                  hint: 'Your contact number',
                                  controller: _phoneController,
                                  prefixIcon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          } else {
                            // On wider screens, keep them side by side
                            return Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    label: 'Your Name',
                                    hint: 'Enter your name',
                                    controller: _nameController,
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    label: 'Phone Number',
                                    hint: 'Your contact number',
                                    controller: _phoneController,
                                    prefixIcon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),

                // Step 3: Confirm booking
                Step(
                  title: const Text('Confirm'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSummaryItem('Service', service.title),
                      _buildSummaryItem(
                        'Area',
                        '${_area.round()} ${service.unit == MeasurementUnit.sqft ? 'sq.ft' : 'inches'}',
                      ),
                      _buildSummaryItem(
                        'Date',
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                      ),
                      _buildSummaryItem(
                        'Time',
                        _selectedTimeSlot?.time ?? 'Not selected',
                      ),
                      _buildSummaryItem('Address', _addressController.text),
                      _buildSummaryItem('Customer', _nameController.text),
                      _buildSummaryItem('Phone', _phoneController.text),

                      const Divider(height: 32),

                      // Get visit charge from selected tier
                      Builder(
                        builder: (context) {
                          final visitCharge =
                              serviceProvider
                                  .getSelectedTierPricing()
                                  ?.visitCharge ??
                              0.0;
                          final serviceCharge = _totalPrice - visitCharge;

                          return Column(
                            children: [
                              // Add a highlighted visit charge section at the top
                              if (visitCharge > 0)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 20,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Visit Charge: ₹${visitCharge.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'You will only pay the visit charge now to confirm your booking. Service charge will be collected afterward.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Payment visualization
                              Container(
                                height: 70,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Payment Breakdown',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '₹${_totalPrice.toStringAsFixed(0)}',
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
                                                  bottomLeft:
                                                      const Radius.circular(12),
                                                  bottomRight:
                                                      serviceCharge <= 0
                                                          ? const Radius.circular(
                                                            12,
                                                          )
                                                          : Radius.zero,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '₹${visitCharge.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color:
                                                          Colors.green.shade800,
                                                    ),
                                                  ),
                                                  const Text(
                                                    'PAY NOW',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        bottomRight:
                                                            Radius.circular(12),
                                                      ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '₹${serviceCharge.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .amber
                                                                .shade800,
                                                      ),
                                                    ),
                                                    Text(
                                                      'PAY LATER',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors
                                                                .amber
                                                                .shade800,
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

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Visit Charge',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${visitCharge.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Service Charge',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '₹${serviceCharge.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.amber.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You will pay only the visit charge (₹${visitCharge.toStringAsFixed(0)}) to confirm your booking. Service charge will be collected after service completion.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${_totalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.payments_outlined),
                            SizedBox(width: 12),
                            Text(
                              'Cash on Delivery',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  isActive: _currentStep >= 2,
                  state: StepState.indexed,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // Removed unused _buildLocalTimeSlots method

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Booking Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppConstants.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(errorMessage, style: const TextStyle(fontSize: 16)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Convert user_models.SavedAddress to booking_models.SavedAddress
  booking_models.SavedAddress _convertToBookingAddress(SavedAddress address) {
    return booking_models.SavedAddress(
      id: address.id,
      label: address.label,
      address: address.address,
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }

  void _navigateToAddAddress() async {
    // Navigate to address screen and wait for result
    final result = await Navigator.pushNamed(
      context,
      '/addresses',
      arguments: 'fromBooking',
    );

    // If a new address was added, refresh user info
    if (result == true && mounted) {
      _prefillUserInfo();
    }
  }

  // Update to save address for future use
  Future<void> _saveAddressToUserProfile(
    String addressText,
    String label,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) return;

    try {
      final newAddress = SavedAddress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: label,
        address: addressText,
        latitude: 0.0, // Default values
        longitude: 0.0,
      );

      await authProvider.addSavedAddress(newAddress);

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Show success toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved to your profile')),
      );
    } catch (e) {
      debugPrint('Error saving address: $e');
    }
  }
}
