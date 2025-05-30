import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fixitpro/models/booking_model.dart';

/// Interface for Firebase service to enable better testability
abstract class IFirebaseService {
  FirebaseFirestore get firestore;
  FirebaseAuth get auth;
  FirebaseStorage get storage;
  bool get isOfflineMode;

  Future<void> initialize();
  Future<bool> checkConnectivity();
  Future<bool> checkCollection(String collectionPath);
  Future<bool> checkAdminAccess();
  Future<bool> isTimeSlotAvailable(String slotId);
  Future<bool> markTimeSlotAsBooked(String slotId, String bookingId);
  Future<List<BookingModel>> loadBookings(String userId);

  // New methods to handle permission errors
  void setOfflineMode(bool isOffline);
  Future<T> safeFirestoreOperation<T>(
    Future<T> Function() operation,
    T defaultValue,
  );
}

/// Implementation of Firebase service that handles all Firebase operations
class FirebaseService implements IFirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  late final FirebaseStorage _storage;

  // State tracking
  bool _isOfflineMode = false;

  // Public getters
  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  FirebaseAuth get auth => _auth;

  @override
  FirebaseStorage get storage => _storage;

  @override
  bool get isOfflineMode => _isOfflineMode;

  @override
  void setOfflineMode(bool isOffline) {
    _isOfflineMode = isOffline;
    debugPrint(
      'Firebase service set to ${isOffline ? 'offline' : 'online'} mode',
    );
  }

  // Generic method to safely execute Firestore operations with error handling
  @override
  Future<T> safeFirestoreOperation<T>(
    Future<T> Function() operation,
    T defaultValue,
  ) async {
    if (_isOfflineMode) {
      return defaultValue;
    }

    try {
      final result = await operation();
      return result;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('Permission denied in Firestore operation: ${e.message}');
        setOfflineMode(true);
      } else {
        debugPrint('Firebase error in operation: ${e.code} - ${e.message}');
      }
      return defaultValue;
    } catch (e) {
      debugPrint('Error in Firestore operation: $e');
      return defaultValue;
    }
  }

  // Initialize the service - must be called after Firebase.initializeApp()
  @override
  Future<void> initialize() async {
    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;

      // Configure Firestore settings for offline persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint('Firebase service initialized successfully');

      // Check connectivity asynchronously
      checkConnectivity().then((isConnected) {
        _isOfflineMode = !isConnected;
        if (_isOfflineMode) {
          debugPrint('App is running in offline mode - using cached data');
        }
      });
    } catch (e) {
      debugPrint('Firebase service initialization failed: $e');
      _isOfflineMode = true;
    }
  }

  // Check if Firebase connectivity is working
  @override
  Future<bool> checkConnectivity() async {
    if (_auth.currentUser == null) {
      return true; // Assume online for unauthenticated users
    }

    try {
      // Simple connectivity test - try to get the user's own document
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      _isOfflineMode = false;
      return true;
    } catch (e) {
      // Handle specific errors differently
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          debugPrint(
            'Permission denied while checking connectivity - this might be expected if rules are strict',
          );
          // User is authenticated but lacks permission to read their own document
          // This might be expected in some security rule configurations
          _isOfflineMode = false;
          return true;
        } else if (e.code == 'unavailable' ||
            e.code == 'network-request-failed') {
          debugPrint('Network connectivity issue detected: ${e.message}');
          _isOfflineMode = true;
          return false;
        }
      }

      debugPrint('Firebase connectivity check failed: $e');
      _isOfflineMode = true;
      return false;
    }
  }

  // Check if a specific collection is accessible
  @override
  Future<bool> checkCollection(String collectionPath) async {
    if (_isOfflineMode) {
      return false;
    }

    return await safeFirestoreOperation<bool>(() async {
      await _firestore
          .collection(collectionPath)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      return true;
    }, false);
  }

  // Check if the current user has admin access
  @override
  Future<bool> checkAdminAccess() async {
    if (_auth.currentUser == null || _isOfflineMode) return false;

    return await safeFirestoreOperation<bool>(() async {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!userDoc.exists) return false;

      return userDoc.data()?['isAdmin'] == true;
    }, false);
  }

  // Check if a time slot is available for booking
  @override
  Future<bool> isTimeSlotAvailable(String slotId) async {
    if (_isOfflineMode) {
      // In offline mode, assume slots are available and handle conflicts later
      return true;
    }

    return await safeFirestoreOperation<bool>(() async {
      // Get the time slot document
      final docSnapshot =
          await _firestore.collection('timeSlots').doc(slotId).get();

      if (!docSnapshot.exists) {
        // Time slot doesn't exist yet, so it's available
        return true;
      }

      final data = docSnapshot.data();
      if (data == null) return false;

      // Check status from the time slot document
      final status = data['status'];
      if (status != 'SlotStatus.available') {
        return false;
      }

      // Check if any bookings exist with this time slot
      final bookingExists = await hasExistingBookingForTimeSlot(slotId);

      // Only available if the slot is marked available and no booking exists for it
      return !bookingExists;
    }, true); // Default to true in case of error to enable offline booking
  }

  // Helper method to check if any bookings already exist with this time slot
  Future<bool> hasExistingBookingForTimeSlot(String slotId) async {
    if (_isOfflineMode) return false;

    return await safeFirestoreOperation<bool>(() async {
      final querySnapshot =
          await _firestore
              .collection('bookings')
              .where('timeSlot.id', isEqualTo: slotId)
              .where(
                'status',
                whereIn: [
                  'BookingStatus.pending',
                  'BookingStatus.confirmed',
                  'BookingStatus.inProgress',
                ],
              )
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    }, false);
  }

  // Mark a time slot as booked in a transaction to prevent race conditions
  @override
  Future<bool> markTimeSlotAsBooked(String slotId, String bookingId) async {
    if (_isOfflineMode) {
      // In offline mode, pretend this succeeded
      return true;
    }

    return await safeFirestoreOperation<bool>(() async {
      // Use a transaction to ensure atomic updates
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get the time slot document
        final docSnapshot = await transaction.get(
          _firestore.collection('timeSlots').doc(slotId),
        );

        // Create new time slot if it doesn't exist
        if (!docSnapshot.exists) {
          transaction.set(_firestore.collection('timeSlots').doc(slotId), {
            'id': slotId,
            'status': 'SlotStatus.booked',
            'bookingId': bookingId,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          return true;
        }

        // Check if the slot is already booked
        final data = docSnapshot.data()!;
        final currentStatus = data['status'];
        if (currentStatus != 'SlotStatus.available') {
          debugPrint(
            'Time slot is already booked: $slotId, status: $currentStatus',
          );
          return false;
        }

        // Update the document with the new status
        transaction.update(_firestore.collection('timeSlots').doc(slotId), {
          'status': 'SlotStatus.booked',
          'bookingId': bookingId,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        return true;
      });
    }, true); // Default to true to allow offline booking
  }

  @override
  Future<List<BookingModel>> loadBookings(String userId) async {
    if (_isOfflineMode) {
      return _loadBookingsFromLocalStorage(userId);
    }

    final bookings = await safeFirestoreOperation<List<BookingModel>>(() async {
      final snapshot =
          await _firestore
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      final bookings =
          snapshot.docs
              .map((doc) => BookingModel.fromJson(doc.data()))
              .toList();

      // Cache the bookings for offline use
      await _saveBookingsToLocalStorage(userId, bookings);

      return bookings;
    }, <BookingModel>[]);

    return bookings.isEmpty
        ? await _loadBookingsFromLocalStorage(userId)
        : bookings;
  }

  // Load time slots for a specific date
  Future<List<TimeSlot>> getTimeSlotsForDate(DateTime date) async {
    // Format date for querying
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_isOfflineMode) {
      return _loadTimeSlotsFromLocalStorage(dateStr);
    }

    return await safeFirestoreOperation<List<TimeSlot>>(() async {
      // Query Firestore for time slots on this date
      final querySnapshot =
          await _firestore
              .collection('timeSlots')
              .where('dateStr', isEqualTo: dateStr)
              .get();

      final slots =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            // Convert the time slot data to our model
            return TimeSlot(
              id: doc.id,
              date:
                  data['date'] is Timestamp
                      ? (data['date'] as Timestamp).toDate()
                      : DateTime.parse(data['date']),
              time: data['time'] as String,
              status:
                  data['status'] == 'SlotStatus.available'
                      ? SlotStatus.available
                      : SlotStatus.booked,
            );
          }).toList();

      // Cache the slots
      await _saveTimeSlotsToLocalStorage(dateStr, slots);

      return slots;
    }, <TimeSlot>[]);
  }

  // Helper method to save time slots to local storage
  Future<void> _saveTimeSlotsToLocalStorage(
    String dateStr,
    List<TimeSlot> slots,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slotsJson = slots.map((slot) => slot.toJson()).toList();
      await prefs.setString('timeSlots_$dateStr', jsonEncode(slotsJson));
    } catch (e) {
      debugPrint('Error saving time slots to local storage: $e');
    }
  }

  // Helper method to load time slots from local storage
  Future<List<TimeSlot>> _loadTimeSlotsFromLocalStorage(String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slotsJson = prefs.getString('timeSlots_$dateStr');
      if (slotsJson == null || slotsJson.isEmpty) {
        return [];
      }

      final slotsData = jsonDecode(slotsJson) as List;
      return slotsData
          .map((data) => TimeSlot.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading time slots from local storage: $e');
      return [];
    }
  }

  // Helper method to save bookings to local storage
  Future<void> _saveBookingsToLocalStorage(
    String userId,
    List<BookingModel> bookings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = bookings.map((booking) => booking.toJson()).toList();
      await prefs.setString('bookings_$userId', jsonEncode(bookingsJson));
    } catch (e) {
      debugPrint('Error saving bookings to local storage: $e');
    }
  }

  // Helper method to load bookings from local storage
  Future<List<BookingModel>> _loadBookingsFromLocalStorage(
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString('bookings_$userId');
      if (bookingsJson == null || bookingsJson.isEmpty) {
        return [];
      }

      final bookingsData = jsonDecode(bookingsJson) as List;
      return bookingsData
          .map((data) => BookingModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading bookings from local storage: $e');
      return [];
    }
  }
}
