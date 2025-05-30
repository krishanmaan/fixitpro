import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitpro/models/admin_model.dart';
import 'package:fixitpro/models/booking_model.dart' as booking_models;
import 'package:fixitpro/models/service_model.dart' as service_models;
import 'package:fixitpro/models/user_model.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  // States
  AdminModel? _currentAdmin;
  List<UserModel> _users = [];
  List<service_models.ServiceModel> _services = [];
  List<booking_models.BookingModel> _bookings = [];
  Map<String, dynamic> _stats = {};
  List<service_models.ServiceTypeModel> _serviceTypes = [];
  bool _isLoading = false;
  String? _error;
  final bool _isOfflineMode = false;

  // Constructor that gets necessary Firebase instances from our service
  AdminProvider()
    : _auth = FirebaseService().auth,
      _firestore = FirebaseService().firestore;

  // Getters
  AdminModel? get currentAdmin => _currentAdmin;
  List<UserModel> get users => _users;
  List<service_models.ServiceModel> get services => _services;
  List<booking_models.BookingModel> get bookings => _bookings;
  List<service_models.ServiceTypeModel> get serviceTypes => _serviceTypes;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdminAuthenticated => _currentAdmin != null;
  bool get isOfflineMode => _isOfflineMode;

  // Check if the current user is an admin
  Future<bool> checkAdminStatus() async {
    if (_auth.currentUser == null) {
      _resetAdminState();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      // Check admin access using our service
      final bool isAdmin = await _firebaseService.checkAdminAccess();

      if (!isAdmin) {
        _resetAdminState();
        return false;
      }

      // If user is admin, try to get their admin profile
      final userId = _auth.currentUser!.uid;

      // Use safeFirestoreOperation to handle permission errors gracefully
      final adminData = await _firebaseService
          .safeFirestoreOperation<Map<String, dynamic>?>(() async {
            final adminDoc =
                await _firestore.collection('admins').doc(userId).get();

            if (adminDoc.exists) {
              return {...adminDoc.data() as Map<String, dynamic>, 'id': userId};
            }
            return null;
          }, null);

      if (adminData != null) {
        _currentAdmin = AdminModel.fromJson(adminData);
      } else {
        // If admin document doesn't exist but user is marked as admin,
        // create a basic admin model from user data
        final userData = await _firebaseService
            .safeFirestoreOperation<Map<String, dynamic>?>(() async {
              final userDoc =
                  await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists) {
                return userDoc.data() as Map<String, dynamic>;
              }
              return null;
            }, null);

        if (userData != null) {
          _currentAdmin = AdminModel(
            id: userId,
            name: userData['name'] ?? 'Admin User',
            email: userData['email'] ?? '',
            phoneNumber: userData['phone'] ?? '',
            isSuperAdmin: false,
            createdAt: DateTime.now(),
          );
        } else {
          // Create minimal admin model if we can't fetch user data
          _currentAdmin = AdminModel(
            id: userId,
            name: 'Admin User',
            email: _auth.currentUser?.email ?? '',
            phoneNumber: _auth.currentUser?.phoneNumber ?? '',
            isSuperAdmin: false,
            createdAt: DateTime.now(),
          );
        }
      }

      _setLoading(false);
      return _currentAdmin != null;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      _error = 'Failed to verify admin status';
      _resetAdminState();
      return false;
    }
  }

  // Reset admin state (used when user is not admin or logs out)
  void _resetAdminState() {
    _setLoading(false);
    _currentAdmin = null;
  }

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    _error = null;

    // Default stats as fallback
    final defaultStats = {
      'userCount': 0,
      'serviceCount': _services.length,
      'pendingBookings': 0,
      'completedBookings': 0,
      'totalRevenue': 0.0,
    };

    if (!await _ensureAdminAccess()) {
      _stats = Map.from(defaultStats);
      _setLoading(false);
      return;
    }

    // Use safeFirestoreOperation for all stats fetching to handle permission errors
    final Map<String, dynamic> newStats = {};

    // Get user count
    final userCount = await _firebaseService.safeFirestoreOperation<int>(
      () async {
        final userSnapshot = await _firestore.collection('users').count().get();
        // Explicitly return int to avoid type issues
        return userSnapshot.count ?? 0;
      },
      0, // Default value as int
    );
    newStats['userCount'] = userCount;

    // Get service count
    final serviceCount = await _firebaseService.safeFirestoreOperation<int>(
      () async {
        final serviceSnapshot =
            await _firestore.collection('services').count().get();
        return serviceSnapshot.count ?? 0;
      },
      defaultStats['serviceCount'] as int,
    );
    newStats['serviceCount'] = serviceCount;

    // Get pending bookings count
    final pendingCount = await _firebaseService.safeFirestoreOperation<int>(
      () async {
        final pendingBookings =
            await _firestore
                .collection('bookings')
                .where('status', isEqualTo: 'BookingStatus.pending')
                .count()
                .get();
        return pendingBookings.count ?? 0;
      },
      0,
    );
    newStats['pendingBookings'] = pendingCount;

    // Get completed bookings count
    final completedCount = await _firebaseService.safeFirestoreOperation<int>(
      () async {
        final completedBookings =
            await _firestore
                .collection('bookings')
                .where('status', isEqualTo: 'BookingStatus.completed')
                .count()
                .get();
        return completedBookings.count ?? 0;
      },
      0,
    );
    newStats['completedBookings'] = completedCount;

    // Get total revenue
    final totalRevenue = await _firebaseService.safeFirestoreOperation<double>(
      () async {
        final revenueSnapshot =
            await _firestore
                .collection('bookings')
                .where('status', isEqualTo: 'BookingStatus.completed')
                .get();

        double total = 0.0;
        for (var doc in revenueSnapshot.docs) {
          final data = doc.data();
          if (data['totalPrice'] != null) {
            total += (data['totalPrice'] as num).toDouble();
          }
        }
        return total;
      },
      0.0,
    );
    newStats['totalRevenue'] = totalRevenue;

    _stats = newStats;
    _setLoading(false);
    notifyListeners();
  }

  // Fetch all users
  Future<void> fetchUsers() async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _users = [];
      _setLoading(false);
      return;
    }

    try {
      // Check if we can access the users collection
      final canAccessUsers = await _firebaseService.checkCollection('users');

      if (!canAccessUsers) {
        _users = [];
        _error = 'Cannot access user data';
        _setLoading(false);
        return;
      }

      // Fetch users
      final snapshot = await _firestore.collection('users').get();
      _users =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return UserModel.fromJson({...data, 'id': doc.id});
          }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _error = 'Failed to load users';
      _users = [];
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all services
  Future<void> fetchServices() async {
    _setLoading(true);
    _error = null;

    try {
      // Check if we can access services (services are public read)
      final canAccessServices = await _firebaseService.checkCollection(
        'services',
      );

      if (!canAccessServices) {
        _error = 'Services not available';
        _setLoading(false);
        return;
      }

      // Fetch services
      final snapshot = await _firestore.collection('services').get();
      _services =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return service_models.ServiceModel.fromJson({
              ...data,
              'id': doc.id,
            });
          }).toList();
    } catch (e) {
      debugPrint('Error fetching services: $e');
      _error = 'Failed to load services';
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all bookings
  Future<void> fetchBookings() async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _bookings = [];
      _setLoading(false);
      return;
    }

    try {
      // Check if we can access the bookings collection
      final canAccessBookings = await _firebaseService.checkCollection(
        'bookings',
      );

      if (!canAccessBookings) {
        _bookings = [];
        _error = 'Cannot access booking data';
        _setLoading(false);
        return;
      }

      // Fetch bookings without complex ordering
      final snapshot = await _firestore.collection('bookings').get();

      _bookings =
          snapshot.docs
              .map((doc) {
                final data = doc.data();

                // Extract timeSlot data
                final timeSlotData = data['timeSlot'] as Map<String, dynamic>;
                final addressData = data['address'] as Map<String, dynamic>;

                try {
                  return booking_models.BookingModel(
                    id: doc.id,
                    userId: data['userId'] as String,
                    serviceId: data['serviceId'] as String,
                    serviceName: data['serviceName'] as String,
                    serviceImage: data['serviceImage'] as String,
                    tierSelected: _getTierTypeFromString(
                      data['tierSelected'] as String,
                    ),
                    area: (data['area'] as num).toDouble(),
                    totalPrice: (data['totalPrice'] as num).toDouble(),
                    status: _getBookingStatusFromString(
                      data['status'] as String,
                    ),
                    address: booking_models.SavedAddress(
                      id: addressData['id'] as String? ?? 'default',
                      label: addressData['label'] as String,
                      address: addressData['address'] as String,
                      latitude: (addressData['latitude'] ?? 0.0) as double,
                      longitude: (addressData['longitude'] ?? 0.0) as double,
                    ),
                    timeSlot: booking_models.TimeSlot(
                      id: timeSlotData['id'] as String? ?? 'default',
                      date: _parseTimestampOrString(timeSlotData['date']),
                      time: timeSlotData['time'] as String,
                      status: _getSlotStatusFromString(
                        timeSlotData['status'] as String,
                      ),
                    ),
                    createdAt: _parseTimestampOrString(data['createdAt']),
                    materialDesignId: data['materialDesignId'] as String?,
                    materialDesignName: data['materialDesignName'] as String?,
                    materialPrice:
                        data['materialPrice'] != null
                            ? (data['materialPrice'] as num).toDouble()
                            : null,
                    reviewId: data['reviewId'] as String?,
                  );
                } catch (e) {
                  debugPrint('Error parsing booking: $e');
                  return null;
                }
              })
              .whereType<booking_models.BookingModel>()
              .toList();

      // Sort locally instead of in the query
      _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('Successfully loaded ${_bookings.length} bookings');
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      _error = 'Failed to load bookings';
      _bookings = [];
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods to convert string values to enum types
  booking_models.TierType _getTierTypeFromString(String value) {
    switch (value) {
      case 'basic':
        return booking_models.TierType.basic;
      case 'standard':
        return booking_models.TierType.standard;
      case 'premium':
        return booking_models.TierType.premium;
      default:
        return booking_models.TierType.basic;
    }
  }

  booking_models.BookingStatus _getBookingStatusFromString(String value) {
    switch (value) {
      case 'pending':
        return booking_models.BookingStatus.pending;
      case 'confirmed':
        return booking_models.BookingStatus.confirmed;
      case 'inProgress':
        return booking_models.BookingStatus.inProgress;
      case 'completed':
        return booking_models.BookingStatus.completed;
      case 'cancelled':
        return booking_models.BookingStatus.cancelled;
      case 'rescheduled':
        return booking_models.BookingStatus.rescheduled;
      default:
        return booking_models.BookingStatus.pending;
    }
  }

  booking_models.SlotStatus _getSlotStatusFromString(String value) {
    switch (value) {
      case 'available':
      case 'SlotStatus.available':
        return booking_models.SlotStatus.available;
      case 'booked':
      case 'SlotStatus.booked':
        return booking_models.SlotStatus.booked;
      default:
        return booking_models.SlotStatus.available;
    }
  }

  // Helper to parse a date from either Timestamp or String
  DateTime _parseTimestampOrString(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        debugPrint('Error parsing date string: $e');
        return DateTime.now();
      }
    } else if (dateValue is DateTime) {
      return dateValue;
    } else {
      debugPrint('Unknown date format: $dateValue (${dateValue.runtimeType})');
      return DateTime.now();
    }
  }

  // Add a new service
  Future<bool> addService(service_models.ServiceModel service) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to add services';
      _setLoading(false);
      return false;
    }

    try {
      final String serviceId = _uuid.v4();

      // Make sure we have the full service type from our loaded types
      final serviceType = _serviceTypes.firstWhere(
        (type) => type.id == service.type.id,
        orElse: () => service.type,
      );

      // Create service with the generated ID
      final newService = service_models.ServiceModel(
        id: serviceId,
        title: service.title,
        description: service.description,
        type: serviceType, // Use the retrieved service type
        unit: service.unit,
        includesMaterial: service.includesMaterial,
        tiers: service.tiers,
        designs: service.designs,
        imageUrl: service.imageUrl,
        categoryId: service.categoryId,
      );

      // Save to Firestore
      await _firestore
          .collection('services')
          .doc(serviceId)
          .set(newService.toJson());

      // Add to local list
      _services.add(newService);
      return true;
    } catch (e) {
      debugPrint('Error adding service: $e');
      _error = 'Failed to add service: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a service
  Future<bool> updateService(service_models.ServiceModel service) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to update services';
      _setLoading(false);
      return false;
    }

    try {
      // Make sure we have the full service type from our loaded types
      final serviceType = _serviceTypes.firstWhere(
        (type) => type.id == service.type.id,
        orElse: () => service.type,
      );

      // Create updated service with the correct service type
      final updatedService = service.copyWith(type: serviceType);

      // Update in local list
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = updatedService;
      }

      // Update in Firestore
      await _firestore
          .collection('services')
          .doc(service.id)
          .update(updatedService.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      _error = 'Failed to update service';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a service
  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to delete services';
      _setLoading(false);
      return false;
    }

    try {
      // Remove from local list
      _services.removeWhere((service) => service.id == serviceId);

      // Delete from Firestore
      await _firestore.collection('services').doc(serviceId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      _error = 'Failed to delete service';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add tier pricing to a service
  Future<bool> addTierPricing(
    String serviceId,
    service_models.TierPricing tier,
  ) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to add tier pricing';
      _setLoading(false);
      return false;
    }

    try {
      // Find the service
      final serviceIndex = _services.indexWhere((s) => s.id == serviceId);
      if (serviceIndex == -1) {
        _error = 'Service not found';
        _setLoading(false);
        return false;
      }

      // Add tier ID if not present
      final tierId = tier.id.isEmpty ? _uuid.v4() : tier.id;
      final newTier = service_models.TierPricing(
        id: tierId,
        serviceId: serviceId,
        tier: tier.tier,
        price: tier.price,
        warrantyMonths: tier.warrantyMonths,
        features: tier.features,
      );

      // Create updated service with new tier
      final service = _services[serviceIndex];
      final updatedTiers = [...service.tiers, newTier];
      final updatedService = service.copyWith(tiers: updatedTiers);

      // Update in local list
      _services[serviceIndex] = updatedService;

      // Update in Firestore
      await _firestore.collection('services').doc(serviceId).update({
        'tiers': updatedTiers.map((t) => t.toJson()).toList(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding tier pricing: $e');
      _error = 'Failed to add tier pricing';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add material design to a service
  Future<bool> addMaterialDesign(
    String serviceId,
    service_models.MaterialDesign design,
  ) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to add material design';
      _setLoading(false);
      return false;
    }

    try {
      // Find the service
      final serviceIndex = _services.indexWhere((s) => s.id == serviceId);
      if (serviceIndex == -1) {
        _error = 'Service not found';
        _setLoading(false);
        return false;
      }

      // Add design ID if not present
      final designId = design.id.isEmpty ? _uuid.v4() : design.id;
      final newDesign = service_models.MaterialDesign(
        id: designId,
        serviceId: serviceId,
        name: design.name,
        pricePerUnit: design.pricePerUnit,
        imageUrl: design.imageUrl,
      );

      // Create updated service with new design
      final service = _services[serviceIndex];
      final updatedDesigns = [...service.designs, newDesign];
      final updatedService = service.copyWith(designs: updatedDesigns);

      // Update in local list
      _services[serviceIndex] = updatedService;

      // Update in Firestore
      await _firestore.collection('services').doc(serviceId).update({
        'designs': updatedDesigns.map((d) => d.toJson()).toList(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding material design: $e');
      _error = 'Failed to add material design';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(
    String bookingId,
    booking_models.BookingStatus status,
  ) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to update booking status';
      _setLoading(false);
      return false;
    }

    try {
      // Update in local list first
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(status: status);
      } else {
        debugPrint('Warning: Booking not found in local list');
      }

      // Update in Firestore
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      _error = 'Failed to update booking status';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create time slots for a date
  Future<bool> createTimeSlotsForDate(
    DateTime date,
    List<String> selectedTimes,
  ) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to create time slots';
      _setLoading(false);
      return false;
    }

    try {
      // Format date to YYYY-MM-DD
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Check if slots already exist for this date and these times
      final existingSlots =
          await _firestore
              .collection('timeSlots')
              .where('dateStr', isEqualTo: dateStr)
              .get();

      // Filter out times that already exist
      final existingTimes =
          existingSlots.docs
              .map((doc) => doc.data()['time'] as String)
              .toList();

      final newTimes =
          selectedTimes.where((time) => !existingTimes.contains(time)).toList();

      if (newTimes.isEmpty) {
        debugPrint('All selected time slots already exist for this date');
        return true;
      }

      // Create batch for efficiency
      final batch = _firestore.batch();

      for (var time in newTimes) {
        final slotId = _uuid.v4();
        final docRef = _firestore.collection('timeSlots').doc(slotId);

        batch.set(docRef, {
          'id': slotId,
          'date': Timestamp.fromDate(date),
          'dateStr': dateStr,
          'time': time,
          'status': 'SlotStatus.available',
          'createdBy': _auth.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint(
        'Successfully created ${newTimes.length} time slots for $dateStr',
      );
      return true;
    } catch (e) {
      debugPrint('Error creating time slots: $e');
      _error = 'Failed to create time slots';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Promote user to admin role
  Future<bool> promoteToAdmin(String userId) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to promote users';
      _setLoading(false);
      return false;
    }

    try {
      // Get user details
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        _error = 'User not found';
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Create admin document
      final adminData = {
        'id': userId,
        'name': userData['name'],
        'email': userData['email'],
        'isSuperAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': userData['phone'],
      };

      // Update user document to mark as admin
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
      });

      // Create admin document
      await _firestore.collection('admins').doc(userId).set(adminData);
      return true;
    } catch (e) {
      debugPrint('Error promoting user to admin: $e');
      _error = 'Failed to promote user to admin';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a time slot
  Future<bool> deleteTimeSlot(String slotId) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to delete time slots';
      _setLoading(false);
      return false;
    }

    try {
      // Check if the slot is already booked
      final slotDoc =
          await _firestore.collection('timeSlots').doc(slotId).get();

      if (!slotDoc.exists) {
        _error = 'Time slot not found';
        _setLoading(false);
        return false;
      }

      final slotData = slotDoc.data() as Map<String, dynamic>;
      if (slotData['status'] == 'SlotStatus.booked') {
        _error = 'Cannot delete a booked time slot';
        _setLoading(false);
        return false;
      }

      // Delete the time slot
      await _firestore.collection('timeSlots').doc(slotId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting time slot: $e');
      _error = 'Failed to delete time slot';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all service types
  Future<void> fetchServiceTypes() async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _serviceTypes = service_models.ServiceTypeModel.defaults;
      _setLoading(false);
      return;
    }

    try {
      // Check if we can access the serviceTypes collection
      final canAccessServiceTypes = await _firebaseService.checkCollection(
        'serviceTypes',
      );

      if (!canAccessServiceTypes) {
        _error = 'Cannot access service type data';
        _setLoading(false);

        // Return default types even if collection not accessible
        _serviceTypes = service_models.ServiceTypeModel.defaults;
        return;
      }

      // Fetch service types
      final snapshot = await _firestore.collection('serviceTypes').get();

      if (snapshot.docs.isEmpty) {
        // If no service types exist in the database, create the default ones
        await _createDefaultServiceTypes();
        _serviceTypes = service_models.ServiceTypeModel.defaults;
      } else {
        // Load service types from Firestore
        _serviceTypes =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return service_models.ServiceTypeModel.fromJson({
                ...data,
                'id': doc.id,
              });
            }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching service types: $e');
      _error = 'Failed to load service types';

      // Return default types even on error
      _serviceTypes = service_models.ServiceTypeModel.defaults;
    } finally {
      _setLoading(false);
    }
  }

  // Create default service types in Firestore if they don't exist
  Future<void> _createDefaultServiceTypes() async {
    final batch = _firestore.batch();

    for (var type in service_models.ServiceTypeModel.defaults) {
      final typeRef = _firestore.collection('serviceTypes').doc(type.id);
      batch.set(typeRef, type.toJson());
    }

    await batch.commit();
    debugPrint('Created default service types in Firestore');
  }

  // Add a new service type
  Future<bool> addServiceType(
    service_models.ServiceTypeModel serviceType,
  ) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to add service types';
      _setLoading(false);
      return false;
    }

    try {
      // Check if service type with same name already exists
      final existingType =
          _serviceTypes
              .where(
                (type) =>
                    type.name.toLowerCase() == serviceType.name.toLowerCase(),
              )
              .toList();

      if (existingType.isNotEmpty) {
        _error = 'A service type with this name already exists';
        _setLoading(false);
        return false;
      }

      final String serviceTypeId =
          serviceType.id.isEmpty ? _uuid.v4() : serviceType.id;

      // Create service type with the generated ID
      final newServiceType = service_models.ServiceTypeModel(
        id: serviceTypeId,
        name: serviceType.name,
        displayName: serviceType.displayName,
        includesMaterial: serviceType.includesMaterial,
        imageUrl: serviceType.imageUrl,
      );

      // Save to Firestore
      await _firestore
          .collection('serviceTypes')
          .doc(serviceTypeId)
          .set(newServiceType.toJson());

      // Add to local list
      _serviceTypes.add(newServiceType);
      return true;
    } catch (e) {
      debugPrint('Error adding service type: $e');
      _error = 'Failed to add service type: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a service type
  Future<bool> updateServiceType(
    service_models.ServiceTypeModel serviceType,
  ) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to update service types';
      _setLoading(false);
      return false;
    }

    try {
      // Check if we're trying to update a default type
      final isDefaultType =
          service_models.ServiceTypeModel.defaults
              .where((type) => type.id == serviceType.id)
              .isNotEmpty;

      if (isDefaultType) {
        _error = 'Cannot update default service types';
        _setLoading(false);
        return false;
      }

      // Update in local list
      final index = _serviceTypes.indexWhere((t) => t.id == serviceType.id);
      if (index != -1) {
        _serviceTypes[index] = serviceType;
      } else {
        _serviceTypes.add(serviceType);
      }

      // Update in Firestore
      await _firestore
          .collection('serviceTypes')
          .doc(serviceType.id)
          .update(serviceType.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating service type: $e');
      _error = 'Failed to update service type';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a service type
  Future<bool> deleteServiceType(String serviceTypeId) async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _error = 'Not authorized to delete service types';
      _setLoading(false);
      return false;
    }

    try {
      // Check if we're trying to delete a default type
      final isDefaultType =
          service_models.ServiceTypeModel.defaults
              .where((type) => type.id == serviceTypeId)
              .isNotEmpty;

      if (isDefaultType) {
        _error = 'Cannot delete default service types';
        _setLoading(false);
        return false;
      }

      // Check if any services are using this type
      final servicesUsingType =
          _services
              .where((service) => service.type.id == serviceTypeId)
              .toList();

      if (servicesUsingType.isNotEmpty) {
        _error = 'Cannot delete service type that is being used by services';
        _setLoading(false);
        return false;
      }

      // Remove from local list
      _serviceTypes.removeWhere((type) => type.id == serviceTypeId);

      // Delete from Firestore
      await _firestore.collection('serviceTypes').doc(serviceTypeId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting service type: $e');
      _error = 'Failed to delete service type';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to ensure admin access before performing operations
  Future<bool> _ensureAdminAccess() async {
    // Check if we're already loaded as admin
    if (_currentAdmin != null) return true;

    // Try to check admin status
    return await checkAdminStatus();
  }

  // Set loading state safely to avoid setState during build
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;

    _isLoading = loading;

    // Use microtask to avoid calling setState during build
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Clear error safely
  void clearError() {
    if (_error == null) return;

    _error = null;

    // Use microtask to avoid calling setState during build
    Future.microtask(() {
      notifyListeners();
    });
  }
}
