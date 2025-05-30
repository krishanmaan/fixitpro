import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/models/user_model.dart' as user_model;
import 'package:uuid/uuid.dart';

/// Service for managing bookings in the application
class BookingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get stream of user bookings for real-time updates
  Stream<List<BookingModel>> getUserBookingsStream() {
    final userId = currentUserId;
    if (userId == null) {
      // Return empty stream if no user is logged in
      return Stream.value([]);
    }

    return _database
        .ref('bookings')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];
          
          final bookingsData = event.snapshot.value as Map<dynamic, dynamic>;
          final List<BookingModel> bookings = [];
          
          bookingsData.forEach((key, value) {
            final booking = BookingModel.fromJson(Map<String, dynamic>.from(value));
            bookings.add(booking);
          });
          
          // Sort by createdAt in descending order
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  /// Get a specific booking as a stream
  Stream<BookingModel?> getBookingStream(String bookingId) {
    return _database
        .ref('bookings/$bookingId')
        .onValue
        .map((event) {
          if (!event.snapshot.exists) return null;
          
          final bookingData = event.snapshot.value as Map<dynamic, dynamic>;
          return BookingModel.fromJson(Map<String, dynamic>.from(bookingData));
        });
  }

  /// Create a new booking
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      final newBookingRef = _database.ref('bookings').push();
      final bookingId = newBookingRef.key!;
      
      // Set the booking ID
      final updatedBooking = booking.copyWith(id: bookingId);
      
      // Save to database
      await newBookingRef.set(updatedBooking.toJson());
      
      return updatedBooking;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'booking-creation-failed',
        message: 'Failed to create booking: ${e.toString()}',
      );
    }
  }

  /// Update an existing booking
  Future<void> updateBooking(BookingModel booking) async {
    try {
      await _database
          .ref('bookings/${booking.id}')
          .update(booking.toJson());
    } catch (e) {
      debugPrint('Error updating booking: $e');
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'booking-update-failed',
        message: 'Failed to update booking: ${e.toString()}',
      );
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _database
          .ref('bookings/$bookingId')
          .update({
            'status': 'BookingStatus.cancelled',
            'updatedAt': ServerValue.timestamp,
          });
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'booking-cancellation-failed',
        message: 'Failed to cancel booking: ${e.toString()}',
      );
    }
  }

  /// Get all bookings (admin only)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      final snapshot = await _database.ref('bookings').get();
      
      if (!snapshot.exists) return [];
      
      final bookingsData = snapshot.value as Map<dynamic, dynamic>;
      final List<BookingModel> bookings = [];
      
      bookingsData.forEach((key, value) {
        final booking = BookingModel.fromJson(Map<String, dynamic>.from(value));
        bookings.add(booking);
      });
      
      // Sort by createdAt in descending order
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    } catch (e) {
      debugPrint('Error getting all bookings: $e');
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'get-bookings-failed',
        message: 'Failed to get bookings: ${e.toString()}',
      );
    }
  }

  /// Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus(String status) async {
    try {
      final snapshot = await _database
          .ref('bookings')
          .orderByChild('status')
          .equalTo(status)
          .get();
      
      if (!snapshot.exists) return [];
      
      final bookingsData = snapshot.value as Map<dynamic, dynamic>;
      final List<BookingModel> bookings = [];
      
      bookingsData.forEach((key, value) {
        final booking = BookingModel.fromJson(Map<String, dynamic>.from(value));
        bookings.add(booking);
      });
      
      // Sort by createdAt in descending order
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    } catch (e) {
      debugPrint('Error getting bookings by status: $e');
      throw FirebaseException(
        plugin: 'firebase_database',
        code: 'get-bookings-failed',
        message: 'Failed to get bookings by status: ${e.toString()}',
      );
    }
  }
}
