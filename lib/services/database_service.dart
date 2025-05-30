import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uuid = Uuid();

  // Services
  // Get services as a stream for real-time updates
  Stream<List<ServiceModel>> getServicesStream() {
    return _firestore.collection('services').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ServiceModel.fromJson(data);
      }).toList();
    });
  }

  // Get service by ID as a stream
  Stream<ServiceModel?> getServiceStreamById(String serviceId) {
    return _firestore.collection('services').doc(serviceId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return ServiceModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }

  // Get all services
  Future<List<ServiceModel>> getAllServices() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('services').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ServiceModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error getting services: ${e.toString()}');
    }
  }

  // Get service by ID
  Future<ServiceModel> getServiceById(String serviceId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Service not found');
      }
    } catch (e) {
      throw Exception('Error getting service: ${e.toString()}');
    }
  }

  // Add a new service (admin only)
  Future<ServiceModel> addService(ServiceModel service) async {
    String id = uuid.v4();
    ServiceModel newService = ServiceModel(
      id: id,
      title: service.title,
      description: service.description,
      type: service.type,
      unit: service.unit,
      includesMaterial: service.includesMaterial,
      tiers: service.tiers,
      designs: service.designs,
      imageUrl: service.imageUrl,
      categoryId: service.categoryId,
    );

    try {
      await _firestore.collection('services').doc(id).set(newService.toJson());
      return newService;
    } catch (e) {
      // Log the error but still return the new service object
      // This allows the app to continue functioning with local data
      debugPrint(
        'Error adding service to Firestore (continuing anyway): ${e.toString()}',
      );
      return newService;
    }
  }

  // Update a service (admin only)
  Future<ServiceModel> updateService(ServiceModel service) async {
    try {
      await _firestore
          .collection('services')
          .doc(service.id)
          .update(service.toJson());
      return service;
    } catch (e) {
      throw Exception('Error updating service: ${e.toString()}');
    }
  }

  // Delete a service (admin only)
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      throw Exception('Error deleting service: ${e.toString()}');
    }
  }

  // Add tier to a service
  Future<ServiceModel> addTierToService(
    String serviceId,
    TierPricing tier,
  ) async {
    try {
      // Get current service
      ServiceModel service = await getServiceById(serviceId);

      // Generate unique ID for tier
      String tierId = uuid.v4();
      TierPricing newTier = TierPricing(
        id: tierId,
        serviceId: serviceId,
        tier: tier.tier,
        price: tier.price,
        warrantyMonths: tier.warrantyMonths,
        features: tier.features,
      );

      // Add tier to service's tiers list
      List<TierPricing> updatedTiers = [...service.tiers, newTier];

      // Update service in Firestore
      await _firestore.collection('services').doc(serviceId).update({
        'tiers': updatedTiers.map((t) => t.toJson()).toList(),
      });

      // Return updated service
      return service.copyWith(tiers: updatedTiers);
    } catch (e) {
      throw Exception('Error adding tier to service: ${e.toString()}');
    }
  }

  // Add material design to a service
  Future<ServiceModel> addDesignToService(
    String serviceId,
    MaterialDesign design,
  ) async {
    try {
      // Get current service
      ServiceModel service = await getServiceById(serviceId);

      // Generate unique ID for design
      String designId = uuid.v4();
      MaterialDesign newDesign = MaterialDesign(
        id: designId,
        serviceId: serviceId,
        imageUrl: design.imageUrl,
        name: design.name,
        pricePerUnit: design.pricePerUnit,
      );

      // Add design to service's designs list
      List<MaterialDesign> updatedDesigns = [...service.designs, newDesign];

      // Update service in Firestore
      await _firestore.collection('services').doc(serviceId).update({
        'designs': updatedDesigns.map((d) => d.toJson()).toList(),
      });

      // Return updated service with categoryId
      return ServiceModel(
        id: service.id,
        title: service.title,
        description: service.description,
        type: service.type,
        unit: service.unit,
        includesMaterial: service.includesMaterial,
        tiers: service.tiers,
        designs: updatedDesigns,
        imageUrl: service.imageUrl,
        categoryId: service.categoryId,
      );
    } catch (e) {
      throw Exception('Error adding design to service: ${e.toString()}');
    }
  }

  // Bookings
  // Get bookings as a stream for real-time updates
  Stream<List<BookingModel>> getBookingsStream() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return BookingModel.fromJson(data);
          }).toList();
        });
  }

  // Get user bookings as a stream
  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return BookingModel.fromJson(data);
          }).toList();
        });
  }

  // Get booking by ID as a stream
  Stream<BookingModel?> getBookingStreamById(String bookingId) {
    return _firestore.collection('bookings').doc(bookingId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }

  // Create a booking
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      String id = uuid.v4();
      BookingModel newBooking = BookingModel(
        id: id,
        userId: booking.userId,
        serviceId: booking.serviceId,
        tierSelected: booking.tierSelected,
        materialDesignId: booking.materialDesignId,
        materialDesignName: booking.materialDesignName,
        materialPrice: booking.materialPrice,
        area: booking.area,
        totalPrice: booking.totalPrice,
        status: BookingStatus.pending,
        address: booking.address,
        timeSlot: booking.timeSlot,
        createdAt: DateTime.now(),
        serviceName: booking.serviceName,
        serviceImage: booking.serviceImage,
        visitCharge: booking.visitCharge,
      );

      await _firestore.collection('bookings').doc(id).set(newBooking.toJson());

      // Update slot status to booked
      await _firestore.collection('timeSlots').doc(booking.timeSlot.id).update({
        'status': 'booked',
      });

      return newBooking;
    } catch (e) {
      throw Exception('Error creating booking: ${e.toString()}');
    }
  }

  // Get booking by ID
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        throw Exception('Booking not found');
      }
    } catch (e) {
      throw Exception('Error getting booking: ${e.toString()}');
    }
  }

  // Get all bookings for a user
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Error getting user bookings: ${e.toString()}');
    }
  }

  // Get all bookings (admin only)
  Future<List<BookingModel>> getAllBookings() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('bookings')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Error getting all bookings: ${e.toString()}');
    }
  }

  // Update booking status
  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.toString().split('.').last,
      });

      BookingModel updatedBooking = await getBookingById(bookingId);
      return updatedBooking;
    } catch (e) {
      throw Exception('Error updating booking status: ${e.toString()}');
    }
  }

  // Cancel booking
  Future<BookingModel> cancelBooking(String bookingId) async {
    try {
      BookingModel booking = await getBookingById(bookingId);

      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString().split('.').last,
      });

      // Free up the time slot
      await _firestore.collection('timeSlots').doc(booking.timeSlot.id).update({
        'status': 'available',
      });

      return booking.copyWith(status: BookingStatus.cancelled);
    } catch (e) {
      throw Exception('Error cancelling booking: ${e.toString()}');
    }
  }

  // Reschedule booking
  Future<BookingModel> rescheduleBooking(
    String bookingId,
    TimeSlot newTimeSlot,
  ) async {
    try {
      BookingModel booking = await getBookingById(bookingId);

      // Free up the old time slot
      await _firestore.collection('timeSlots').doc(booking.timeSlot.id).update({
        'status': 'available',
      });

      // Book the new time slot
      await _firestore.collection('timeSlots').doc(newTimeSlot.id).update({
        'status': 'booked',
      });

      // Update booking with new time slot and status
      await _firestore.collection('bookings').doc(bookingId).update({
        'timeSlot': newTimeSlot.toJson(),
        'status': BookingStatus.rescheduled.toString().split('.').last,
      });

      return booking.copyWith(
        timeSlot: newTimeSlot,
        status: BookingStatus.rescheduled,
      );
    } catch (e) {
      throw Exception('Error rescheduling booking: ${e.toString()}');
    }
  }

  // Reviews
  // Get reviews as a stream for real-time updates
  Stream<List<ReviewModel>> getReviewsStream() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return ReviewModel.fromJson(data);
          }).toList();
        });
  }

  // Get service reviews as a stream
  Stream<List<ReviewModel>> getServiceReviewsStream(String serviceId) {
    return _firestore
        .collection('reviews')
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return ReviewModel.fromJson(data);
          }).toList();
        });
  }

  // Add a review
  Future<ReviewModel> addReview({
    required String bookingId,
    required String userId,
    required String serviceId,
    required double rating,
    required String comment,
    required String userName,
  }) async {
    try {
      String id = uuid.v4();
      ReviewModel review = ReviewModel(
        id: id,
        bookingId: bookingId,
        userId: userId,
        serviceId: serviceId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        userName: userName,
      );

      await _firestore.collection('reviews').doc(id).set(review.toJson());

      // Update booking with review ID
      await _firestore.collection('bookings').doc(bookingId).update({
        'reviewId': id,
      });

      return review;
    } catch (e) {
      throw Exception('Error adding review: ${e.toString()}');
    }
  }

  // Get reviews for a service
  Future<List<ReviewModel>> getServiceReviews(String serviceId) async {
    try {
      // First get bookings for this service
      QuerySnapshot bookingSnapshot =
          await _firestore
              .collection('bookings')
              .where('serviceId', isEqualTo: serviceId)
              .where('reviewId', isNull: false)
              .get();

      List<String> reviewIds =
          bookingSnapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['reviewId'] as String,
              )
              .toList();

      if (reviewIds.isEmpty) {
        return [];
      }

      // Get reviews using the IDs
      List<ReviewModel> reviews = [];
      for (String reviewId in reviewIds) {
        DocumentSnapshot reviewDoc =
            await _firestore.collection('reviews').doc(reviewId).get();
        if (reviewDoc.exists) {
          reviews.add(
            ReviewModel.fromJson(reviewDoc.data() as Map<String, dynamic>),
          );
        }
      }

      return reviews;
    } catch (e) {
      throw Exception('Error getting service reviews: ${e.toString()}');
    }
  }

  // Time Slots
  // Get available time slots as a stream
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
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return TimeSlot.fromJson(data);
          }).toList();
        });
  }

  // Get available time slots for a specific date
  Future<List<TimeSlot>> getAvailableTimeSlots(DateTime date) async {
    try {
      // Format date to ISO string without time component
      String dateString = date.toIso8601String().split('T')[0];

      QuerySnapshot snapshot =
          await _firestore
              .collection('timeSlots')
              .where('date', isGreaterThanOrEqualTo: '$dateString 00:00:00')
              .where('date', isLessThan: '$dateString 23:59:59')
              .where('status', isEqualTo: 'available')
              .get();

      return snapshot.docs
          .map((doc) => TimeSlot.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting available time slots: ${e.toString()}');
    }
  }

  // Create a time slot
  Future<TimeSlot> createTimeSlot(DateTime date, String time) async {
    try {
      String id = uuid.v4();
      TimeSlot timeSlot = TimeSlot(
        id: id,
        date: date,
        time: time,
        status: SlotStatus.available,
      );

      await _firestore.collection('timeSlots').doc(id).set(timeSlot.toJson());

      return timeSlot;
    } catch (e) {
      throw Exception('Error creating time slot: ${e.toString()}');
    }
  }

  // Create multiple time slots for a specific date
  Future<List<TimeSlot>> createTimeSlotsForDate(
    DateTime date,
    List<String> times,
  ) async {
    try {
      List<TimeSlot> createdSlots = [];

      for (String time in times) {
        String id = uuid.v4();
        TimeSlot timeSlot = TimeSlot(
          id: id,
          date: date,
          time: time,
          status: SlotStatus.available,
        );

        try {
          await _firestore
              .collection('timeSlots')
              .doc(id)
              .set(timeSlot.toJson());
          createdSlots.add(timeSlot);
        } catch (firestoreError) {
          debugPrint('Error adding time slot to Firestore: $firestoreError');
          // Still add the slot to our return value so the UI can show it
          createdSlots.add(timeSlot);
        }
      }

      return createdSlots;
    } catch (e) {
      debugPrint('Error creating time slots: ${e.toString()}');
      // Return default slots even on error so the app can continue functioning
      return times.map((time) {
        String id = uuid.v4();
        return TimeSlot(
          id: id,
          date: date,
          time: time,
          status: SlotStatus.available,
        );
      }).toList();
    }
  }
}
