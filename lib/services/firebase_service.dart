import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fixitpro/models/booking_model.dart';

/// Interface for Firebase service to enable better testability
abstract class IFirebaseService {
  FirebaseDatabase get database;
  FirebaseAuth get auth;
  FirebaseStorage get storage;
  bool get isOfflineMode;

  Future<void> initialize();
  Future<bool> checkConnectivity();
  Future<bool> checkCollection(String path);
  Future<bool> checkAdminAccess();
  Future<bool> isTimeSlotAvailable(String slotId);
  Future<bool> markTimeSlotAsBooked(String slotId, String bookingId);
  Future<List<BookingModel>> loadBookings(String userId);
  Future<List<BookingModel>> getTimeSlotsForDate(DateTime date);

  void setOfflineMode(bool isOffline);
  Future<T> safeRealtimeDatabaseOperation<T>(
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
  late final FirebaseDatabase _database;
  late final FirebaseAuth _auth;
  late final FirebaseStorage _storage;

  // State tracking
  bool _isOfflineMode = false;

  // Public getters
  @override
  FirebaseDatabase get database => _database;

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

  // Initialize the service - must be called after Firebase.initializeApp()
  @override
  Future<void> initialize() async {
    try {
      _database = FirebaseDatabase.instance;
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;

      // Configure Realtime Database for offline persistence
      _database.setPersistenceEnabled(true);
      _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache

      // Enable logging in debug mode
      if (kDebugMode) {
        FirebaseDatabase.instance.setLoggingEnabled(true);
      }

      // Test database connection
      try {
        final ref = _database.ref('.info/connected');
        ref.onValue.listen((event) {
          final connected = event.snapshot.value as bool? ?? false;
          debugPrint('Firebase Realtime Database connection state: ${connected ? 'connected' : 'disconnected'}');
          _isOfflineMode = !connected;
        });
      } catch (e) {
        debugPrint('Error setting up database connection listener: $e');
      }

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

  // Generic method to safely execute Realtime Database operations with error handling
  @override
  Future<T> safeRealtimeDatabaseOperation<T>(
    Future<T> Function() operation,
    T defaultValue,
  ) async {
    if (_isOfflineMode) {
      debugPrint('Operation attempted in offline mode - returning default value');
      return defaultValue;
    }

    try {
      debugPrint('Starting database operation...');
      final result = await operation();
      debugPrint('Database operation completed successfully');
      return result;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error details:');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Stack trace: ${e.stackTrace}');

      if (e.code == 'permission-denied') {
        debugPrint('Permission denied - Current user ID: ${_auth.currentUser?.uid}');
        debugPrint('Permission denied in Realtime Database operation. Check your database rules.');
        
        // Try to get the current user's admin status for debugging
        try {
          final userRef = _database.ref('users/${_auth.currentUser?.uid}');
          final userSnapshot = await userRef.get();
          if (userSnapshot.exists) {
            final userData = userSnapshot.value as Map<dynamic, dynamic>;
            debugPrint('User admin status: ${userData['isAdmin']}');
          } else {
            debugPrint('User document not found');
          }
        } catch (innerError) {
          debugPrint('Error checking user status: $innerError');
        }
        
        setOfflineMode(true);
      } else {
        debugPrint('Firebase error in operation: ${e.code} - ${e.message}');
      }
      return defaultValue;
    } catch (e, stackTrace) {
      debugPrint('Error in Realtime Database operation:');
      debugPrint(e.toString());
      debugPrint('Stack trace:');
      debugPrint(stackTrace.toString());
      return defaultValue;
    }
  }

  // Check if Firebase connectivity is working
  @override
  Future<bool> checkConnectivity() async {
    if (_auth.currentUser == null) {
      return true; // Assume online for unauthenticated users
    }

    try {
      // Simple connectivity test - try to get the user's own data
      final ref = _database.ref('users/${_auth.currentUser!.uid}');
      await ref.get();
      _isOfflineMode = false;
      return true;
    } catch (e) {
      if (e is FirebaseException) {
        if (e.code == 'permission-denied') {
          debugPrint(
            'Permission denied while checking connectivity - this might be expected if rules are strict',
          );
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

  // Check if a specific path is accessible
  @override
  Future<bool> checkCollection(String path) async {
    if (_isOfflineMode) {
      return false;
    }

    return await safeRealtimeDatabaseOperation<bool>(() async {
      final ref = _database.ref(path);
      final snapshot = await ref.limitToFirst(1).get();
      return snapshot.exists;
    }, false);
  }

  // Check if the current user has admin access
  @override
  Future<bool> checkAdminAccess() async {
    debugPrint('Checking admin access...');
    if (_auth.currentUser == null) {
      debugPrint('No user is logged in');
      return false;
    }

    return await safeRealtimeDatabaseOperation<bool>(() async {
      final userId = _auth.currentUser!.uid;
      debugPrint('Checking admin status for user: $userId');
      
      // First check if user exists and is admin
      final userSnapshot = await _database.ref('users/$userId').get();
      
      if (!userSnapshot.exists) {
        debugPrint('User document not found');
        return false;
      }
      
      final userData = userSnapshot.value as Map<dynamic, dynamic>;
      final isAdmin = userData['isAdmin'] == true;
      
      debugPrint('User isAdmin status: $isAdmin');
      
      if (!isAdmin) {
        debugPrint('User is not marked as admin');
        return false;
      }

      // Verify admin document exists
      final adminSnapshot = await _database.ref('admins/$userId').get();
      final hasAdminDoc = adminSnapshot.exists;
      debugPrint('Admin document exists: $hasAdminDoc');

      if (!hasAdminDoc) {
        // Create admin document if it doesn't exist
        debugPrint('Creating admin document...');
        try {
          await _database.ref('admins/$userId').set({
            'id': userId,
            'name': userData['name'] ?? 'Admin User',
            'email': userData['email'] ?? _auth.currentUser?.email ?? '',
            'phoneNumber': userData['phone'] ?? '',
            'isSuperAdmin': false,
            'createdAt': ServerValue.timestamp,
          });
          debugPrint('Admin document created successfully');
          return true;
        } catch (e) {
          debugPrint('Error creating admin document: $e');
          return false;
        }
      }

      return true;
    }, false);
  }

  // Check if a time slot is available for booking
  @override
  Future<bool> isTimeSlotAvailable(String slotId) async {
    if (_isOfflineMode) {
      // In offline mode, assume slots are available and handle conflicts later
      return true;
    }

    return await safeRealtimeDatabaseOperation<bool>(() async {
      final ref = _database.ref('timeSlots/$slotId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return true;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      if (data['status'] != 'SlotStatus.available') {
        return false;
      }

      // Check if any bookings exist with this time slot
      final bookingRef = _database.ref('bookings');
      final bookingQuery = bookingRef.orderByChild('timeSlotId').equalTo(slotId);
      final bookingSnapshot = await bookingQuery.get();

      return !bookingSnapshot.exists;
    }, true);
  }

  // Mark a time slot as booked
  @override
  Future<bool> markTimeSlotAsBooked(String slotId, String bookingId) async {
    if (_isOfflineMode) return false;

    return await safeRealtimeDatabaseOperation<bool>(() async {
      final ref = _database.ref('timeSlots/$slotId');
      await ref.update({
        'status': 'SlotStatus.booked',
        'bookingId': bookingId,
        'updatedAt': ServerValue.timestamp,
      });
      return true;
    }, false);
  }

  // Load bookings for a user
  @override
  Future<List<BookingModel>> loadBookings(String userId) async {
    if (_isOfflineMode) {
      return _loadBookingsFromLocalStorage(userId);
    }

    final bookings = await safeRealtimeDatabaseOperation<List<BookingModel>>(() async {
      final ref = _database.ref('bookings');
      final query = ref.orderByChild('userId').equalTo(userId);
      final snapshot = await query.get();

      if (!snapshot.exists) return [];

      final bookingsData = snapshot.value as Map<dynamic, dynamic>;
      final List<BookingModel> bookings = [];

      bookingsData.forEach((key, value) {
        final booking = BookingModel.fromJson(Map<String, dynamic>.from(value));
        bookings.add(booking);
      });

      // Sort bookings by createdAt in descending order
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the bookings for offline use
      await _saveBookingsToLocalStorage(userId, bookings);

      return bookings;
    }, <BookingModel>[]);

    return bookings.isEmpty
        ? await _loadBookingsFromLocalStorage(userId)
        : bookings;
  }

  // Helper method to load bookings from local storage
  Future<List<BookingModel>> _loadBookingsFromLocalStorage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? bookingsJson = prefs.getString('bookings_$userId');
      if (bookingsJson == null) return [];

      final List<dynamic> bookingsList = jsonDecode(bookingsJson);
      return bookingsList
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading bookings from local storage: $e');
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
      final String bookingsJson = jsonEncode(
        bookings.map((booking) => booking.toJson()).toList(),
      );
      await prefs.setString('bookings_$userId', bookingsJson);
    } catch (e) {
      debugPrint('Error saving bookings to local storage: $e');
    }
  }

  // Get time slots for a specific date
  @override
  Future<List<BookingModel>> getTimeSlotsForDate(DateTime date) async {
    if (_isOfflineMode) {
      return [];
    }

    final dateStr = date.toIso8601String().split('T')[0];

    return await safeRealtimeDatabaseOperation<List<BookingModel>>(() async {
      final ref = _database.ref('timeSlots').orderByChild('dateStr').equalTo(dateStr);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final slotsData = snapshot.value as Map<dynamic, dynamic>;
      return slotsData.entries.map((entry) {
        final data = entry.value as Map<dynamic, dynamic>;
        return BookingModel.fromJson({
          ...data,
          'id': entry.key,
        });
      }).toList();
    }, []);
  }
}
