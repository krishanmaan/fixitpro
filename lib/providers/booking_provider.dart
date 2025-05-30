import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitpro/models/booking_model.dart' as booking_models;
import 'package:fixitpro/models/service_model.dart' hide TierType;

import 'package:fixitpro/services/database_service.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  final uuid = Uuid();

  List<booking_models.BookingModel> _userBookings = [];
  List<booking_models.BookingModel> _allBookings = []; // for admin
  List<booking_models.TimeSlot> _availableSlots = [];
  booking_models.TimeSlot? _selectedTimeSlot;
  booking_models.SavedAddress? _selectedAddress;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;

  // Getters
  List<booking_models.BookingModel> get userBookings => _userBookings;
  List<booking_models.BookingModel> get allBookings => _allBookings;
  List<booking_models.TimeSlot> get availableSlots => _availableSlots;
  booking_models.TimeSlot? get selectedTimeSlot => _selectedTimeSlot;
  booking_models.SavedAddress? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;

  // Check Firebase access permissions
  Future<bool> _checkFirebasePermissions() async {
    try {
      // Try a simple read operation
      await _firestore.collection('app_settings').doc('info').get();
      _isOfflineMode = false;
      return true;
    } catch (e) {
      debugPrint('Firebase permission check failed: $e');
      _isOfflineMode = true;
      return false;
    }
  }

  // Load user bookings
  Future<void> loadUserBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Save existing bookings to preserve them
    List<booking_models.BookingModel> existingBookings = List.from(
      _userBookings,
    );

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId == null) {
          _userBookings = [];
          return;
        }

        // Get only current user's bookings by filtering with userId
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .get();

        if (bookingsSnapshot.docs.isNotEmpty) {
          _userBookings =
              bookingsSnapshot.docs.map((doc) {
                final data = doc.data();
                final id = doc.id;

                // Manual mapping from Firestore document
                final timeSlotData = data['timeSlot'] as Map<String, dynamic>;
                final addressData = data['address'] as Map<String, dynamic>;

                return booking_models.BookingModel(
                  id: id,
                  userId: data['userId'] as String,
                  serviceId: data['serviceId'] as String,
                  serviceName: data['serviceName'] as String,
                  serviceImage: data['serviceImage'] as String,
                  tierSelected: _getTierTypeFromString(
                    data['tierSelected'] as String,
                  ),
                  area: (data['area'] as num).toDouble(),
                  totalPrice: (data['totalPrice'] as num).toDouble(),
                  status: _getBookingStatusFromString(data['status'] as String),
                  address: booking_models.SavedAddress(
                    id: addressData['id'] as String? ?? 'default',
                    label: addressData['label'] as String,
                    address: addressData['address'] as String,
                    latitude: (addressData['latitude'] ?? 0.0) as double,
                    longitude: (addressData['longitude'] ?? 0.0) as double,
                  ),
                  timeSlot: booking_models.TimeSlot(
                    id: timeSlotData['id'] as String? ?? 'default',
                    date: _parseDate(timeSlotData['date']),
                    time: timeSlotData['time'] as String,
                    status: _getSlotStatusFromString(
                      timeSlotData['status'] as String,
                    ),
                  ),
                  createdAt: _parseDate(data['createdAt']),
                  materialDesignId: data['materialDesignId'] as String?,
                  materialDesignName: data['materialDesignName'] as String?,
                  materialPrice:
                      data['materialPrice'] != null
                          ? (data['materialPrice'] as num).toDouble()
                          : null,
                  reviewId: data['reviewId'] as String?,
                  visitCharge:
                      data['visitCharge'] != null
                          ? (data['visitCharge'] as num).toDouble()
                          : null,
                );
              }).toList();

          // Sort locally by creation date (descending)
          _userBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Save bookings to local storage for offline access
          saveBookingsToLocalStorage(_userBookings);
        } else {
          // If no bookings in Firestore, use existing ones or try to load from storage
          if (existingBookings.isNotEmpty) {
            _userBookings = existingBookings;
          } else {
            // Try to load from local storage as last resort
            final localBookings = await _loadBookingsFromLocalStorage();
            if (localBookings.isNotEmpty) {
              _userBookings = localBookings;
              _isOfflineMode = true;
            } else {
              _userBookings = [];
            }
          }
        }
      } else {
        // Offline mode - keep existing bookings or try to load from storage
        _isOfflineMode = true;
        if (existingBookings.isNotEmpty) {
          _userBookings = existingBookings;
        } else {
          final localBookings = await _loadBookingsFromLocalStorage();
          if (localBookings.isNotEmpty) {
            _userBookings = localBookings;
          } else {
            _userBookings = [];
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user bookings: $e');
      // In case of errors, keep existing bookings
      if (existingBookings.isNotEmpty) {
        _userBookings = existingBookings;
      } else {
        // Try to load from local storage if we don't have existing bookings
        try {
          final localBookings = await _loadBookingsFromLocalStorage();
          if (localBookings.isNotEmpty) {
            _userBookings = localBookings;
            _isOfflineMode = true;
          }
        } catch (storageError) {
          debugPrint('Error loading from local storage: $storageError');
        }

        // Only use empty list if really nothing is available
        if (_userBookings.isEmpty) {
          _userBookings = [];
        }
      }
      _isOfflineMode = true;
      _error = 'Failed to load bookings. Using cached data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to save bookings to local storage
  Future<void> saveBookingsToLocalStorage(
    List<booking_models.BookingModel> bookings,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = bookings.map((booking) => booking.toMap()).toList();
      await prefs.setString('user_bookings_$currentUserId', jsonEncode(bookingsJson));
    } catch (e) {
      debugPrint('Error saving bookings to local storage: $e');
    }
  }

  // Helper method to load bookings from local storage
  Future<List<booking_models.BookingModel>>
  _loadBookingsFromLocalStorage() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];
      
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString('user_bookings_$currentUserId');
      if (bookingsJson == null || bookingsJson.isEmpty) {
        return [];
      }

      final bookingsData = jsonDecode(bookingsJson) as List;
      final bookings = bookingsData
          .map(
            (data) => booking_models.BookingModel.fromMap(
              data as Map<String, dynamic>,
            ),
          )
          .toList();
          
      // Additional filter to ensure only current user's bookings are loaded
      return bookings.where((booking) => booking.userId == currentUserId).toList();
    } catch (e) {
      debugPrint('Error loading bookings from local storage: $e');
      return [];
    }
  }

  // Helper methods to convert string values to enum types
  booking_models.TierType _getTierTypeFromString(String value) {
    switch (value) {
      case 'TierType.basic':
        return booking_models.TierType.basic;
      case 'TierType.standard':
        return booking_models.TierType.standard;
      case 'TierType.premium':
        return booking_models.TierType.premium;
      default:
        return booking_models.TierType.basic;
    }
  }

  booking_models.BookingStatus _getBookingStatusFromString(String value) {
    switch (value) {
      case 'BookingStatus.pending':
        return booking_models.BookingStatus.pending;
      case 'BookingStatus.confirmed':
        return booking_models.BookingStatus.confirmed;
      case 'BookingStatus.inProgress':
        return booking_models.BookingStatus.inProgress;
      case 'BookingStatus.completed':
        return booking_models.BookingStatus.completed;
      case 'BookingStatus.cancelled':
        return booking_models.BookingStatus.cancelled;
      case 'BookingStatus.rescheduled':
        return booking_models.BookingStatus.rescheduled;
      default:
        return booking_models.BookingStatus.pending;
    }
  }

  booking_models.SlotStatus _getSlotStatusFromString(String value) {
    switch (value) {
      case 'SlotStatus.available':
        return booking_models.SlotStatus.available;
      case 'SlotStatus.booked':
        return booking_models.SlotStatus.booked;
      default:
        return booking_models.SlotStatus.available;
    }
  }

  // Load all bookings (admin only)
  Future<void> loadAllBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Get all bookings without filtering by user ID
        final bookingsSnapshot =
            await _firestore
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .get();

        if (bookingsSnapshot.docs.isNotEmpty) {
          _allBookings =
              bookingsSnapshot.docs.map((doc) {
                final data = doc.data();
                final id = doc.id;

                // Manual mapping from Firestore document
                final timeSlotData = data['timeSlot'] as Map<String, dynamic>;
                final addressData = data['address'] as Map<String, dynamic>;

                return booking_models.BookingModel(
                  id: id,
                  userId: data['userId'] as String,
                  serviceId: data['serviceId'] as String,
                  serviceName: data['serviceName'] as String,
                  serviceImage: data['serviceImage'] as String,
                  tierSelected: _getTierTypeFromString(
                    data['tierSelected'] as String,
                  ),
                  area: (data['area'] as num).toDouble(),
                  totalPrice: (data['totalPrice'] as num).toDouble(),
                  status: _getBookingStatusFromString(data['status'] as String),
                  address: booking_models.SavedAddress(
                    id: addressData['id'] as String? ?? 'default',
                    label: addressData['label'] as String,
                    address: addressData['address'] as String,
                    latitude: (addressData['latitude'] ?? 0.0) as double,
                    longitude: (addressData['longitude'] ?? 0.0) as double,
                  ),
                  timeSlot: booking_models.TimeSlot(
                    id: timeSlotData['id'] as String? ?? 'default',
                    date: _parseDate(timeSlotData['date']),
                    time: timeSlotData['time'] as String,
                    status: _getSlotStatusFromString(
                      timeSlotData['status'] as String,
                    ),
                  ),
                  createdAt: _parseDate(data['createdAt']),
                  materialDesignId: data['materialDesignId'] as String?,
                  materialDesignName: data['materialDesignName'] as String?,
                  materialPrice:
                      data['materialPrice'] != null
                          ? (data['materialPrice'] as num).toDouble()
                          : null,
                  reviewId: data['reviewId'] as String?,
                  visitCharge:
                      data['visitCharge'] != null
                          ? (data['visitCharge'] as num).toDouble()
                          : null,
                );
              }).toList();
        } else {
          _allBookings = [];
        }
      } else {
        _isOfflineMode = true;
        _allBookings = [];
      }
    } catch (e) {
      debugPrint('Error loading all bookings: $e');
      _isOfflineMode = true;
      _error = 'Failed to load bookings. Please try again later.';
      _allBookings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available time slots for a specific date
  Future<void> loadAvailableTimeSlots(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to use the FirebaseService which has better error handling
      final slots = await _firebaseService.getTimeSlotsForDate(date);

      if (slots.isNotEmpty) {
        // Convert Firebase TimeSlot to booking_models.TimeSlot
        _availableSlots =
            slots
                .map(
                  (slot) => booking_models.TimeSlot(
                    id: slot.id,
                    date: slot.date,
                    time: slot.time,
                    status:
                        slot.status == booking_models.SlotStatus.available
                            ? booking_models.SlotStatus.available
                            : booking_models.SlotStatus.booked,
                  ),
                )
                .toList();

        _isLoading = false;
        notifyListeners();
        return;
      }

      // If we have no slots from Firebase, check if we have existing bookings
      // to avoid showing slots that we know are already booked
      List<booking_models.TimeSlot> bookedSlots = [];

      // Extract booked slots from user's bookings for this date
      for (var booking in _userBookings) {
        if (booking.timeSlot.date.year == date.year &&
            booking.timeSlot.date.month == date.month &&
            booking.timeSlot.date.day == date.day) {
          bookedSlots.add(booking.timeSlot);
        }
      }

      // Generate default time slots for the date, excluding booked ones
      _availableSlots = _generateDefaultTimeSlots(date, bookedSlots);
    } catch (e) {
      debugPrint('Error loading time slots: $e');

      // Fallback to default slots on error
      _availableSlots = _generateDefaultTimeSlots(date, []);
      _error = 'Could not load time slots from server. Using default schedule.';
      _isOfflineMode = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate default time slots for a date
  List<booking_models.TimeSlot> _generateDefaultTimeSlots(
    DateTime date,
    List<booking_models.TimeSlot> bookedSlots,
  ) {
    final defaultSlots = <booking_models.TimeSlot>[];

    // Default time slots from 9 AM to 6 PM
    final defaultTimes = [
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
    ];

    for (final time in defaultTimes) {
      // Check if this time is already booked
      final isBooked = bookedSlots.any((slot) => slot.time == time);

      defaultSlots.add(
        booking_models.TimeSlot(
          id: 'default_${date.toIso8601String()}_$time',
          date: date,
          time: time,
          status:
              isBooked
                  ? booking_models.SlotStatus.booked
                  : booking_models.SlotStatus.available,
        ),
      );
    }

    return defaultSlots;
  }

  // Select a time slot
  void selectTimeSlot(booking_models.TimeSlot slot) {
    _selectedTimeSlot = slot;
    notifyListeners();
  }

  // Select an address
  void selectAddress(booking_models.SavedAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Create a booking
  Future<booking_models.BookingModel?> createBooking({
    required String userId,
    required ServiceModel service,
    required booking_models.TierType tierSelected,
    required double area,
    required double totalPrice,
    required booking_models.SavedAddress address,
    required booking_models.TimeSlot timeSlot,
    String? materialDesignId,
    double? visitCharge,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    booking_models.BookingModel? newBooking;

    try {
      if (_auth.currentUser == null) {
        throw 'User not authenticated';
      }

      final bookingId = uuid.v4();
      final now = DateTime.now();
      final dateStr =
          '${timeSlot.date.year}-${timeSlot.date.month.toString().padLeft(2, '0')}-${timeSlot.date.day.toString().padLeft(2, '0')}';

      // Get material design details if provided
      String? materialDesignName;
      double? materialPrice;

      if (materialDesignId != null && materialDesignId.isNotEmpty) {
        final materialDesignDoc =
            await _firestore
                .collection('services')
                .doc(service.id)
                .collection('materialDesigns')
                .doc(materialDesignId)
                .get();

        if (materialDesignDoc.exists) {
          final data = materialDesignDoc.data();
          materialDesignName = data?['name'] as String?;
          materialPrice =
              data?['price'] != null
                  ? (data!['price'] as num).toDouble()
                  : null;
        }
      }

      // Create booking model
      newBooking = booking_models.BookingModel(
        id: bookingId,
        userId: userId,
        serviceId: service.id,
        serviceName: service.title,
        serviceImage: service.imageUrl,
        tierSelected: tierSelected,
        area: area,
        totalPrice: totalPrice,
        status: booking_models.BookingStatus.pending,
        address: address,
        timeSlot: timeSlot,
        createdAt: now,
        materialDesignId: materialDesignId,
        materialDesignName: materialDesignName,
        materialPrice: materialPrice,
        visitCharge: visitCharge,
      );

      // Use a transaction to ensure consistent booking of the time slot
      await _firestore.runTransaction((transaction) async {
        // Generate a consistent time slot ID for checking and creation
        final timeSlotId = '${dateStr}_${timeSlot.id}';

        try {
          // First check if the time slot is available
          final timeSlotDoc = await transaction.get(
            _firestore.collection('timeSlots').doc(timeSlotId),
          );

          if (timeSlotDoc.exists) {
            final slotData = timeSlotDoc.data();
            if (slotData != null && slotData['status'] == 'SlotStatus.booked') {
              throw 'Selected time slot has already been booked';
            }
          }
          // Time slot doesn't exist, we'll create it below

          // The time slot is available (or will be created), create the booking
          transaction.set(_firestore.collection('bookings').doc(bookingId), {
            'userId': userId,
            'serviceId': service.id,
            'serviceName': service.title,
            'serviceImage': service.imageUrl,
            'tierSelected': tierSelected.toString(),
            'area': area,
            'totalPrice': totalPrice,
            'status': 'BookingStatus.pending',
            'address': {
              'id': address.id,
              'label': address.label,
              'address': address.address,
              'latitude': address.latitude,
              'longitude': address.longitude,
            },
            'timeSlot': {
              'id': timeSlot.id,
              'date': Timestamp.fromDate(timeSlot.date),
              'time': timeSlot.time,
              'status': 'SlotStatus.booked',
              'dateStr': dateStr,
            },
            'createdAt': Timestamp.fromDate(now),
            'materialDesignId': materialDesignId,
            'materialDesignName': materialDesignName,
            'materialPrice': materialPrice,
            'visitCharge': visitCharge,
            'isActive':
                true, // Add isActive flag to ensure booking is always shown
            'isPermanent':
                true, // Add isPermanent flag to ensure booking is never deleted on refresh
          });

          // Create or update the time slot
          transaction.set(
            _firestore.collection('timeSlots').doc(timeSlotId),
            {
              'id': timeSlot.id,
              'date': Timestamp.fromDate(timeSlot.date),
              'time': timeSlot.time,
              'status': 'SlotStatus.booked',
              'dateStr': dateStr,
              'bookedBy': userId,
              'bookingId': bookingId,
              'lastUpdated': Timestamp.fromDate(now),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          if (e is String &&
              e == 'Selected time slot has already been booked') {
            // Rethrow the error with the custom message
            rethrow;
          } else {
            // Handle other transaction errors
            debugPrint('Error in booking transaction: $e');
            throw 'Failed to create booking. Please try again.';
          }
        }
      });

      // After successful Firestore update, update local state
      _userBookings.insert(0, newBooking);

      // Save updated bookings to local storage for offline access
      saveBookingsToLocalStorage(_userBookings);
    } catch (e) {
      debugPrint('Error creating booking: $e');
      _error = e.toString();
      newBooking = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return newBooking;
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _error = null;

    try {
      // Only update in Firestore if we're not in offline mode
      if (!_isOfflineMode) {
        try {
          await _firestore.collection('bookings').doc(bookingId).update({
            'status': booking_models.BookingStatus.cancelled.toString(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        } catch (e) {
          debugPrint('Error updating booking in Firestore: $e');
          _isOfflineMode = true;
        }
      }

      // Always update local list
      int index = _userBookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (index != -1) {
        booking_models.BookingModel updatedBooking = _userBookings[index]
            .copyWith(status: booking_models.BookingStatus.cancelled);
        _userBookings[index] = updatedBooking;

        if (_selectedTimeSlot?.id == bookingId) {
          _selectedTimeSlot = null;
          _selectedAddress = null;
        }
      }

      // Update in all bookings if admin
      int adminIndex = _allBookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (adminIndex != -1) {
        _allBookings[adminIndex] = _allBookings[adminIndex].copyWith(
          status: booking_models.BookingStatus.cancelled,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reschedule a booking
  Future<bool> rescheduleBooking(
    String bookingId,
    booking_models.TimeSlot newTimeSlot,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      // Format date to YYYY-MM-DD for easier querying
      final dateStr =
          '${newTimeSlot.date.year}-${newTimeSlot.date.month.toString().padLeft(2, '0')}-${newTimeSlot.date.day.toString().padLeft(2, '0')}';

      // Only update in Firestore if we're not in offline mode
      if (!_isOfflineMode) {
        try {
          await _firestore.collection('bookings').doc(bookingId).update({
            'timeSlot': {
              'id': newTimeSlot.id,
              'date': Timestamp.fromDate(newTimeSlot.date),
              'time': newTimeSlot.time,
              'status': newTimeSlot.status.toString(),
            },
            'dateStr': dateStr,
            'status': booking_models.BookingStatus.rescheduled.toString(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        } catch (e) {
          debugPrint('Error updating booking in Firestore: $e');
          _isOfflineMode = true;
        }
      }

      // Always update local list
      int index = _userBookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (index != -1) {
        booking_models.BookingModel updatedBooking = _userBookings[index]
            .copyWith(
              timeSlot: newTimeSlot,
              status: booking_models.BookingStatus.rescheduled,
            );
        _userBookings[index] = updatedBooking;

        if (_selectedTimeSlot?.id == bookingId) {
          _selectedTimeSlot = null;
          _selectedAddress = null;
        }
      }

      // Update in all bookings if admin
      int adminIndex = _allBookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (adminIndex != -1) {
        _allBookings[adminIndex] = _allBookings[adminIndex].copyWith(
          timeSlot: newTimeSlot,
          status: booking_models.BookingStatus.rescheduled,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error rescheduling booking: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update booking status (admin only)
  Future<bool> updateBookingStatus(
    String bookingId,
    booking_models.BookingStatus status,
  ) async {
    _isLoading = true;
    _error = null;

    try {
      // Only update in Firestore if we're not in offline mode
      if (!_isOfflineMode) {
        try {
          await _firestore.collection('bookings').doc(bookingId).update({
            'status': status.toString(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            // Add payment info for completed bookings
            if (status == booking_models.BookingStatus.completed)
              'serviceChargePaid': true,
          });
        } catch (e) {
          debugPrint('Error updating booking in Firestore: $e');
          _isOfflineMode = true;
        }
      }

      // Always update local list
      int index = _userBookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (index != -1) {
        booking_models.BookingModel updatedBooking = _userBookings[index]
            .copyWith(
              status: status,
              // Set serviceChargePaid to true if status is completed
              serviceChargePaid:
                  status == booking_models.BookingStatus.completed
                      ? true
                      : _userBookings[index].serviceChargePaid,
            );
        _userBookings[index] = updatedBooking;
      }

      // Update in all bookings if admin
      int adminIndex = _allBookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (adminIndex != -1) {
        _allBookings[adminIndex] = _allBookings[adminIndex].copyWith(
          status: status,
          // Set serviceChargePaid to true if status is completed
          serviceChargePaid:
              status == booking_models.BookingStatus.completed
                  ? true
                  : _allBookings[adminIndex].serviceChargePaid,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a review
  Future<bool> addReview({
    required String bookingId,
    required String userId,
    required double rating,
    required String comment,
    required String userName,
  }) async {
    _isLoading = true;
    _error = null;

    try {
      final uuid = const Uuid();
      final reviewId = uuid.v4();

      // Get booking details
      booking_models.BookingModel? booking = getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      // Only update in Firestore if we're not in offline mode
      if (!_isOfflineMode) {
        try {
          // Create review in Firestore
          await _firestore.collection('reviews').doc(reviewId).set({
            'id': reviewId,
            'bookingId': bookingId,
            'userId': userId,
            'serviceId': booking.serviceId,
            'rating': rating,
            'comment': comment,
            'userName': userName,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

          // Update booking with review ID
          await _firestore.collection('bookings').doc(bookingId).update({
            'reviewId': reviewId,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        } catch (e) {
          debugPrint('Error saving review to Firestore: $e');
          _isOfflineMode = true;
        }
      }

      // Always update local list
      int index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        booking_models.BookingModel updatedBooking = _userBookings[index]
            .copyWith(reviewId: reviewId);
        _userBookings[index] = updatedBooking;

        if (_selectedTimeSlot?.id == bookingId) {
          _selectedTimeSlot = null;
          _selectedAddress = null;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create time slots for a date (admin only)
  Future<bool> createTimeSlotsForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create a list of default time slots
      List<String> defaultTimeSlots = [
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
        '18:00',
      ];

      try {
        // Use the improved database service method that handles errors internally
        await _databaseService.createTimeSlotsForDate(date, defaultTimeSlots);
        // Reload available time slots
        await loadAvailableTimeSlots(date);
      } catch (e) {
        debugPrint('Error creating time slots: $e');
        _isOfflineMode = true;
        // Still provide default time slots
        _availableSlots = _generateDefaultTimeSlots(date, []);
      }

      return true;
    } catch (e) {
      debugPrint('Error in createTimeSlotsForDate: $e');
      _error = 'Could not create time slots: ${e.toString()}';
      // Make sure we always have some time slots
      _availableSlots = _generateDefaultTimeSlots(date, []);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get booking by ID
  booking_models.BookingModel? getBookingById(String bookingId) {
    try {
      return _userBookings.firstWhere((booking) => booking.id == bookingId);
    } catch (e) {
      try {
        return _allBookings.firstWhere((booking) => booking.id == bookingId);
      } catch (e) {
        return null;
      }
    }
  }

  // Get filtered bookings by status
  List<booking_models.BookingModel> getFilteredBookings(
    booking_models.BookingStatus? status,
  ) {
    if (status == null) {
      return _userBookings;
    }
    return _userBookings.where((booking) => booking.status == status).toList();
  }

  // Get admin filtered bookings by status
  List<booking_models.BookingModel> getAdminFilteredBookings(
    booking_models.BookingStatus? status,
  ) {
    if (status == null) {
      return _allBookings;
    }
    return _allBookings.where((booking) => booking.status == status).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset selections
  void resetSelections() {
    _selectedTimeSlot = null;
    _selectedAddress = null;
    notifyListeners();
  }

  // Get bookings filtered by status
  List<booking_models.BookingModel> getBookingsByStatus(
    booking_models.BookingStatus status,
  ) {
    return _userBookings.where((booking) => booking.status == status).toList();
  }

  // Get review details by ID
  Future<Map<String, dynamic>?> getReviewDetails(String reviewId) async {
    try {
      if (_isOfflineMode) {
        // In offline mode, we can't fetch review details
        return null;
      }

      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();

      if (!reviewDoc.exists) {
        return null;
      }

      final data = reviewDoc.data() as Map<String, dynamic>;
      return {
        'id': data['id'] ?? reviewId,
        'bookingId': data['bookingId'] ?? '',
        'userId': data['userId'] ?? '',
        'serviceId': data['serviceId'] ?? '',
        'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        'comment': data['comment'] ?? '',
        'userName': data['userName'] ?? 'Anonymous',
        'createdAt':
            data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error fetching review details: $e');
      return null;
    }
  }

  // Helper method to parse date from different formats
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('Error parsing date string: $e');
        return DateTime.now();
      }
    } else if (dateValue is int) {
      // Handle milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    } else {
      debugPrint('Unknown date format: $dateValue (${dateValue?.runtimeType})');
      return DateTime.now();
    }
  }
}
