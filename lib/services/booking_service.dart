import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/models/user_model.dart' as user_model;
import 'package:uuid/uuid.dart';

/// Service for managing bookings in the application
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => BookingModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  /// Get a specific booking as a stream
  Stream<BookingModel?> getBookingStream(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Get all bookings as a stream (admin only)
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => BookingModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  /// Create a new booking
  Future<BookingModel> createBooking({
    required String serviceId,
    required String serviceName,
    required String serviceImage,
    required TierType tierSelected,
    required double area,
    required double totalPrice,
    required user_model.SavedAddress address,
    required TimeSlot timeSlot,
    String? materialDesignId,
    String? materialDesignName,
    double? materialPrice,
    double? visitCharge,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unauthenticated',
          message: 'User is not authenticated',
        );
      }

      // Check if time slot is available
      final isAvailable = await _isTimeSlotAvailable(timeSlot.id);
      if (!isAvailable) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Selected time slot is no longer available',
        );
      }

      // Create a SavedAddress from UserModel.SavedAddress
      final bookingAddress = SavedAddress(
        id: address.id,
        label: address.label,
        address: address.address,
        latitude: address.latitude,
        longitude: address.longitude,
      );

      // Generate booking ID
      String id = _uuid.v4();
      BookingModel newBooking = BookingModel(
        id: id,
        userId: userId,
        serviceId: serviceId,
        tierSelected: tierSelected,
        materialDesignId: materialDesignId,
        materialDesignName: materialDesignName,
        materialPrice: materialPrice,
        area: area,
        totalPrice: totalPrice,
        status: BookingStatus.pending,
        address: bookingAddress,
        timeSlot: timeSlot,
        createdAt: DateTime.now(),
        serviceName: serviceName,
        serviceImage: serviceImage,
        visitCharge: visitCharge,
        serviceChargePaid: false,
      );

      // Use a transaction to ensure atomic operations
      await _firestore.runTransaction((transaction) async {
        // Mark time slot as booked
        transaction.set(_firestore.collection('timeSlots').doc(timeSlot.id), {
          'id': timeSlot.id,
          'date': timeSlot.date.toIso8601String(),
          'time': timeSlot.time,
          'status': 'SlotStatus.booked',
          'bookingId': id,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create booking document
        transaction.set(
          _firestore.collection('bookings').doc(id),
          newBooking.toJson(),
        );
      });

      return newBooking;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  /// Check if a time slot is available
  Future<bool> _isTimeSlotAvailable(String slotId) async {
    try {
      // Get the time slot document from Firestore
      final docSnapshot =
          await _firestore.collection('timeSlots').doc(slotId).get();

      // If the document doesn't exist, the slot is available
      if (!docSnapshot.exists) {
        return true;
      }

      // Check if the slot status is available
      final data = docSnapshot.data();
      if (data != null) {
        final status = data['status'];
        return status == 'SlotStatus.available';
      }

      return false;
    } catch (e) {
      debugPrint('Error checking time slot availability: $e');
      return false;
    }
  }

  /// Get available time slots for a date
  Stream<List<TimeSlot>> getAvailableTimeSlotsStream(DateTime date) {
    // Format date to ISO string without time component
    final dateString =
        DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String().split('T')[0];

    return _firestore
        .collection('timeSlots')
        .where('date', isGreaterThanOrEqualTo: '${dateString}T00:00:00.000')
        .where('date', isLessThan: '${dateString}T23:59:59.999')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) {
                    final data = doc.data();
                    return TimeSlot(
                      id: doc.id,
                      date: DateTime.parse(data['date']),
                      time: data['time'],
                      status:
                          data['status'] == 'SlotStatus.available'
                              ? SlotStatus.available
                              : SlotStatus.booked,
                    );
                  })
                  .where((slot) => slot.status == SlotStatus.available)
                  .toList(),
        );
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      // Get current booking
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Booking not found',
        );
      }

      final bookingData = bookingDoc.data()!;
      final timeSlotId = bookingData['timeSlot']['id'];

      // Use a transaction to ensure atomic operations
      await _firestore.runTransaction((transaction) async {
        // Mark booking as cancelled
        transaction.update(_firestore.collection('bookings').doc(bookingId), {
          'status': BookingStatus.cancelled.toString().split('.').last,
        });

        // Free up the time slot
        transaction.update(_firestore.collection('timeSlots').doc(timeSlotId), {
          'status': 'SlotStatus.available',
          'bookingId': null,
        });
      });
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Reschedule booking
  Future<void> rescheduleBooking(String bookingId, TimeSlot newTimeSlot) async {
    try {
      // Get current booking
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Booking not found',
        );
      }

      final bookingData = bookingDoc.data()!;
      final oldTimeSlotId = bookingData['timeSlot']['id'];

      // Use a transaction to ensure atomic operations
      await _firestore.runTransaction((transaction) async {
        // Free up the old time slot
        transaction.update(
          _firestore.collection('timeSlots').doc(oldTimeSlotId),
          {'status': 'SlotStatus.available', 'bookingId': null},
        );

        // Book the new time slot
        transaction.update(
          _firestore.collection('timeSlots').doc(newTimeSlot.id),
          {'status': 'SlotStatus.booked', 'bookingId': bookingId},
        );

        // Update booking with new time slot
        transaction.update(_firestore.collection('bookings').doc(bookingId), {
          'timeSlot': newTimeSlot.toJson(),
          'status': BookingStatus.rescheduled.toString().split('.').last,
        });
      });
    } catch (e) {
      debugPrint('Error rescheduling booking: $e');
      rethrow;
    }
  }
}
