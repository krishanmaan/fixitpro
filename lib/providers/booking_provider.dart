import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fixitpro/models/booking_model.dart' as booking_models;
import 'package:fixitpro/models/service_model.dart' hide TierType;

import 'package:fixitpro/services/database_service.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookingProvider with ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
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
      await _database.ref('app_settings/info').get();
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
        // Get all bookings
        final bookingsSnapshot = await _database.ref('bookings').get();

        if (bookingsSnapshot.exists) {
          final bookingsData = bookingsSnapshot.value as Map<dynamic, dynamic>;
          _userBookings = bookingsData.entries.map((entry) {
            final data = entry.value as Map<dynamic, dynamic>;
            final id = entry.key as String;

            // Manual mapping from Realtime Database
            final timeSlotData = data['timeSlot'] as Map<dynamic, dynamic>;
            final addressData = data['address'] as Map<dynamic, dynamic>;

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
                date: DateTime.parse(timeSlotData['date'] as String),
                time: timeSlotData['time'] as String,
                status: _getSlotStatusFromString(
                  timeSlotData['status'] as String,
                ),
              ),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                data['createdAt'] as int,
              ),
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
          // If no bookings in database, use existing ones or try to load from storage
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
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = bookings.map((booking) => booking.toMap()).toList();
      await prefs.setString('user_bookings', jsonEncode(bookingsJson));
    } catch (e) {
      debugPrint('Error saving bookings to local storage: $e');
    }
  }

  // Helper method to load bookings from local storage
  Future<List<booking_models.BookingModel>> _loadBookingsFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString('user_bookings');
      if (bookingsJson != null) {
        final List<dynamic> bookingsData = jsonDecode(bookingsJson);
        return bookingsData
            .map((data) => booking_models.BookingModel.fromMap(
                  data as Map<String, dynamic>,
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading bookings from local storage: $e');
    }
    return [];
  }

  // Helper method to parse dates from Realtime Database
  DateTime _parseDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now(); // Fallback
  }

  // Helper method to convert string to TierType enum
  booking_models.TierType _getTierTypeFromString(String tierStr) {
    switch (tierStr) {
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

  // Helper method to convert string to BookingStatus enum
  booking_models.BookingStatus _getBookingStatusFromString(String statusStr) {
    switch (statusStr) {
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
      default:
        return booking_models.BookingStatus.pending;
    }
  }

  // Helper method to convert string to SlotStatus enum
  booking_models.SlotStatus _getSlotStatusFromString(String statusStr) {
    switch (statusStr) {
      case 'SlotStatus.available':
        return booking_models.SlotStatus.available;
      case 'SlotStatus.booked':
        return booking_models.SlotStatus.booked;
      default:
        return booking_models.SlotStatus.available;
    }
  }

  // Create a new booking
  Future<bool> createBooking(booking_models.BookingModel booking) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Save to Realtime Database
        await _database.ref('bookings/${booking.id}').set({
          ...booking.toMap(),
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });

        // Update time slot status
        await _database.ref('timeSlots/${booking.timeSlot.id}').update({
          'status': 'SlotStatus.booked',
          'bookingId': booking.id,
          'updatedAt': ServerValue.timestamp,
        });

        // Add to local list
        _userBookings.add(booking);
        _userBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Save to local storage
        await saveBookingsToLocalStorage(_userBookings);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Cannot create booking in offline mode';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      _error = 'Failed to create booking';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Update in Realtime Database
        await _database.ref('bookings/$bookingId').update({
          'status': 'BookingStatus.cancelled',
          'updatedAt': ServerValue.timestamp,
        });

        // Update local list
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _userBookings[index] = _userBookings[index].copyWith(
            status: booking_models.BookingStatus.cancelled,
          );
          await saveBookingsToLocalStorage(_userBookings);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Cannot cancel booking in offline mode';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      _error = 'Failed to cancel booking';
      _isLoading = false;
      notifyListeners();
      return false;
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
            await _database.ref('bookings').get();

        if (bookingsSnapshot.exists) {
          final bookingsData = bookingsSnapshot.value as Map<dynamic, dynamic>;
          _allBookings = bookingsData.entries.map((entry) {
            final data = entry.value as Map<dynamic, dynamic>;
            final id = entry.key as String;

            // Manual mapping from Realtime Database
            final timeSlotData = data['timeSlot'] as Map<dynamic, dynamic>;
            final addressData = data['address'] as Map<dynamic, dynamic>;

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
                date: DateTime.parse(timeSlotData['date'] as String),
                time: timeSlotData['time'] as String,
                status: _getSlotStatusFromString(
                  timeSlotData['status'] as String,
                ),
              ),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                data['createdAt'] as int,
              ),
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

  // Load available time slots for a date
  Future<void> loadAvailableTimeSlots(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Get time slots for the date
        final slots = await _firebaseService.getTimeSlotsForDate(date);
        _availableSlots = slots
            .where((slot) => slot.timeSlot.status == booking_models.SlotStatus.available)
            .map((slot) => slot.timeSlot)
            .toList();
      } else {
        _availableSlots = [];
        _error = 'Cannot load time slots in offline mode';
      }
    } catch (e) {
      debugPrint('Error loading time slots: $e');
      _error = 'Failed to load time slots';
      _availableSlots = [];
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
          await _database.ref('reviews/$reviewId').get();

      if (!reviewDoc.exists) {
        return null;
      }

      final data = reviewDoc.value as Map<dynamic, dynamic>;
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
                ? (data['createdAt'] as num).toDouble()
                : DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error fetching review details: $e');
      return null;
    }
  }

  // Add a review to a booking
  Future<bool> addReview({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        final booking = getBookingById(bookingId);
        if (booking == null) {
          _error = 'Booking not found';
          return false;
        }

        final reviewId = uuid.v4();
        final reviewData = {
          'id': reviewId,
          'bookingId': bookingId,
          'userId': _auth.currentUser?.uid,
          'serviceId': booking.serviceId,
          'rating': rating,
          'comment': comment,
          'userName': _auth.currentUser?.displayName ?? 'Anonymous',
          'createdAt': ServerValue.timestamp,
        };

        // Save review
        await _database.ref('reviews/$reviewId').set(reviewData);

        // Update booking with review ID
        await _database.ref('bookings/$bookingId').update({
          'reviewId': reviewId,
          'updatedAt': ServerValue.timestamp,
        });

        // Update local booking
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _userBookings[index] = _userBookings[index].copyWith(
            reviewId: reviewId,
          );
        }

        return true;
      } else {
        _error = 'Cannot add review in offline mode';
        return false;
      }
    } catch (e) {
      debugPrint('Error adding review: $e');
      _error = 'Failed to add review';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(
    String bookingId,
    booking_models.BookingStatus newStatus,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Update in Realtime Database
        await _database.ref('bookings/$bookingId').update({
          'status': newStatus.toString(),
          'updatedAt': ServerValue.timestamp,
        });

        // Update local list
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _userBookings[index] = _userBookings[index].copyWith(
            status: newStatus,
          );
          await saveBookingsToLocalStorage(_userBookings);
        }

        return true;
      } else {
        _error = 'Cannot update booking status in offline mode';
        return false;
      }
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      _error = 'Failed to update booking status';
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
    notifyListeners();

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        final booking = getBookingById(bookingId);
        if (booking == null) {
          _error = 'Booking not found';
          return false;
        }

        // Update old time slot status
        await _database.ref('timeSlots/${booking.timeSlot.id}').update({
          'status': 'SlotStatus.available',
          'bookingId': null,
          'updatedAt': ServerValue.timestamp,
        });

        // Update new time slot status
        await _database.ref('timeSlots/${newTimeSlot.id}').update({
          'status': 'SlotStatus.booked',
          'bookingId': bookingId,
          'updatedAt': ServerValue.timestamp,
        });

        // Update booking
        await _database.ref('bookings/$bookingId').update({
          'timeSlot': newTimeSlot.toJson(),
          'status': 'BookingStatus.rescheduled',
          'updatedAt': ServerValue.timestamp,
        });

        // Update local list
        final index = _userBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _userBookings[index] = _userBookings[index].copyWith(
            timeSlot: newTimeSlot,
            status: booking_models.BookingStatus.rescheduled,
          );
          await saveBookingsToLocalStorage(_userBookings);
        }

        return true;
      } else {
        _error = 'Cannot reschedule booking in offline mode';
        return false;
      }
    } catch (e) {
      debugPrint('Error rescheduling booking: $e');
      _error = 'Failed to reschedule booking';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
