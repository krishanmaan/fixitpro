import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitpro/models/booking_model.dart' as booking_models;
import 'package:fixitpro/models/service_model.dart' as service_models;
import 'package:fixitpro/models/user_model.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  // States
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;
  final Map<String, dynamic> _dashboardStats = {
    'userCount': 0,
    'serviceCount': 0,
    'pendingBookings': 0,
    'completedBookings': 0,
    'totalRevenue': 0.0,
  };
  List<UserModel> _users = [];
  List<service_models.ServiceModel> _services = [];
  List<booking_models.BookingModel> _bookings = [];
  List<service_models.ServiceTypeModel> _serviceTypes = [];
  bool _isOfflineMode = false;

  // Constructor - Check admin status when provider is created
  AdminProvider() {
    checkAdminStatus();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _isAdmin;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<UserModel> get users => _users;
  List<service_models.ServiceModel> get services => _services;
  List<booking_models.BookingModel> get bookings => _bookings;
  List<service_models.ServiceTypeModel> get serviceTypes => _serviceTypes;
  bool get isOfflineMode => _isOfflineMode;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Check if current user is admin
  Future<bool> checkAdminStatus() async {
    debugPrint('Checking admin status...');
    if (_auth.currentUser == null) {
      debugPrint('No user logged in');
      _isAdmin = false;
      notifyListeners();
      return false;
    }

    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('Checking admin status for user: $userId');

      // First check user document
      final userSnapshot = await _database
          .ref('users/$userId')
          .get();

      if (!userSnapshot.exists) {
        debugPrint('User document not found');
        _isAdmin = false;
        notifyListeners();
        return false;
      }

      final userData = userSnapshot.value as Map<dynamic, dynamic>;
      final isAdminInUser = userData['isAdmin'] == true;
      debugPrint('User isAdmin status from users collection: $isAdminInUser');

      if (!isAdminInUser) {
        debugPrint('User is not marked as admin in users collection');
        _isAdmin = false;
        notifyListeners();
        return false;
      }

      // Then verify admin document exists
      final adminSnapshot = await _database
          .ref('admins/$userId')
          .get();

      if (!adminSnapshot.exists) {
        debugPrint('Admin document not found, creating one...');
        // Create admin document
        await _database.ref('admins/$userId').set({
          'email': userData['email'] ?? _auth.currentUser?.email ?? '',
          'name': userData['name'] ?? 'Admin User',
          'createdAt': ServerValue.timestamp,
        });
        debugPrint('Admin document created');
      } else {
        debugPrint('Admin document exists');
      }
      
      _isAdmin = true;
      debugPrint('Admin status confirmed: $_isAdmin');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      _isAdmin = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    if (!_isAdmin) {
      _error = 'Not authorized';
      return;
    }

    _setLoading(true);
    try {
      // Get users count
      final usersSnapshot = await _database.ref('users').get();
      if (usersSnapshot.exists) {
        final usersData = usersSnapshot.value as Map<dynamic, dynamic>;
        _dashboardStats['userCount'] = usersData.length;
        debugPrint('Users count: ${usersData.length}');
      }

      // Get services count
      final servicesSnapshot = await _database.ref('services').get();
      if (servicesSnapshot.exists) {
        final servicesData = servicesSnapshot.value as Map<dynamic, dynamic>;
        _dashboardStats['serviceCount'] = servicesData.length;
      }

      // Get pending bookings
      final pendingSnapshot = await _database
          .ref('bookings')
          .orderByChild('status')
          .equalTo('pending')
          .get();
      if (pendingSnapshot.exists) {
        final pendingData = pendingSnapshot.value as Map<dynamic, dynamic>;
        _dashboardStats['pendingBookings'] = pendingData.length;
      }

      // Get completed bookings and calculate revenue
      final completedSnapshot = await _database
          .ref('bookings')
          .orderByChild('status')
          .equalTo('completed')
          .get();
      if (completedSnapshot.exists) {
        final completedData = completedSnapshot.value as Map<dynamic, dynamic>;
        _dashboardStats['completedBookings'] = completedData.length;

        double totalRevenue = 0.0;
        completedData.forEach((key, value) {
          final booking = value as Map<dynamic, dynamic>;
          if (booking['totalPrice'] != null) {
            totalRevenue += (booking['totalPrice'] as num).toDouble();
          }
        });
        _dashboardStats['totalRevenue'] = totalRevenue;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      _error = 'Failed to load statistics';
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all users
  Future<void> fetchUsers() async {
    _setLoading(true);
    _error = null;

    if (!await _ensureAdminAccess()) {
      _users = [];
      _error = 'Not authorized to access user data';
      _setLoading(false);
      return;
    }

    try {
      // Fetch users directly since we've already checked admin access
      final snapshot = await _firebaseService.safeRealtimeDatabaseOperation<DataSnapshot?>(() async {
        return await _database.ref('users').get();
      }, null);

      if (snapshot == null || !snapshot.exists) {
        _users = [];
        _error = 'No users found';
        _setLoading(false);
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      _users = data.entries.map((entry) {
        final userData = entry.value as Map<dynamic, dynamic>;
        return UserModel.fromJson({
          ...Map<String, dynamic>.from(userData),
          'id': entry.key,
        });
          }).toList();

      debugPrint('Successfully loaded ${_users.length} users');
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _error = 'Failed to load users';
      _users = [];
    } finally {
      _setLoading(false);
      notifyListeners();
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
      final snapshot = await _database.ref('services').get();
      _services =
          snapshot.children.map((child) {
            final data = child.value as Map<dynamic, dynamic>;
            return service_models.ServiceModel.fromJson({
              ...data,
              'id': child.key,
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
      final snapshot = await _database.ref('bookings').get();

      _bookings =
          snapshot.children
              .map((child) {
                final data = child.value as Map<dynamic, dynamic>;

                // Extract timeSlot data
                final timeSlotData = data['timeSlot'] as Map<dynamic, dynamic>;
                final addressData = data['address'] as Map<dynamic, dynamic>;

                try {
                  return booking_models.BookingModel(
                    id: child.key!,
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
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
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

  // Fetch service types
  Future<void> fetchServiceTypes() async {
    _setLoading(true);
    _error = null;

    try {
      final snapshot = await _database.ref('serviceTypes').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _serviceTypes = data.entries.map((entry) {
          return service_models.ServiceTypeModel.fromJson({
            ...Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>),
            'id': entry.key,
          });
        }).toList();
      } else {
        // If no service types exist, create default ones
        await _createDefaultServiceTypes();
      }
    } catch (e) {
      debugPrint('Error fetching service types: $e');
      _error = 'Failed to load service types';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Create default service types if none exist
  Future<void> _createDefaultServiceTypes() async {
    try {
      final defaultTypes = [
        {
          'id': 'repair',
          'name': 'Repair',
          'description': 'Repair services',
          'icon': 'build',
        },
        {
          'id': 'installation',
          'name': 'Installation',
          'description': 'Installation services',
          'icon': 'settings',
        },
        {
          'id': 'maintenance',
          'name': 'Maintenance',
          'description': 'Maintenance services',
          'icon': 'handyman',
        },
      ];

      for (final type in defaultTypes) {
        await _database.ref('serviceTypes/${type['id']}').set(type);
      }

      _serviceTypes = defaultTypes.map((type) => 
        service_models.ServiceTypeModel.fromJson(Map<String, dynamic>.from(type))
      ).toList();
    } catch (e) {
      debugPrint('Error creating default service types: $e');
    }
  }

  // Add a new service
  Future<bool> addService(service_models.ServiceModel service) async {
    if (!_isAdmin) return false;

    try {
      final serviceData = service.toJson();
      final newServiceRef = _database.ref('services').push();
      await newServiceRef.set({
        ...serviceData,
        'id': newServiceRef.key,
        'createdAt': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding service: $e');
      _error = 'Failed to add service';
      return false;
    }
  }

  // Update a service
  Future<bool> updateService(String serviceId, service_models.ServiceModel service) async {
    if (!_isAdmin) return false;

    try {
      await _database.ref('services/$serviceId').update(service.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      _error = 'Failed to update service';
      return false;
    }
  }

  // Add tier pricing to a service
  Future<bool> addTierPricing(String serviceId, service_models.TierPricing tier) async {
    if (!_isAdmin) return false;

    try {
      final tierId = tier.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : tier.id;
      await _database.ref('services/$serviceId/tiers/$tierId').set(tier.toJson());
      return true;
    } catch (e) {
      debugPrint('Error adding tier pricing: $e');
      _error = 'Failed to add tier pricing';
      return false;
    }
  }

  // Add material design to a service
  Future<bool> addMaterialDesign(String serviceId, service_models.MaterialDesign design) async {
    if (!_isAdmin) return false;

    try {
      final designId = design.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : design.id;
      await _database.ref('services/$serviceId/designs/$designId').set(design.toJson());
      return true;
    } catch (e) {
      debugPrint('Error adding material design: $e');
      _error = 'Failed to add material design';
      return false;
    }
  }

  // Delete a service
  Future<bool> deleteService(String serviceId) async {
    if (!_isAdmin) return false;

    try {
      await _database.ref('services/$serviceId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      _error = 'Failed to delete service';
      return false;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, booking_models.BookingStatus status) async {
    if (!_isAdmin) return false;

    try {
      await _database.ref('bookings/$bookingId').update({
        'status': status.toString().split('.').last,
        'updatedAt': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      _error = 'Failed to update booking';
      return false;
    }
  }

  // Helper method to ensure admin access before performing operations
  Future<bool> _ensureAdminAccess() async {
    debugPrint('Ensuring admin access...');
    if (!_isAdmin) {
      debugPrint('No admin profile found, checking admin status...');
      return await checkAdminStatus();
    }
    debugPrint('Admin profile exists, access granted');
    return true;
  }

  // Debug method to check admin status
  Future<void> debugCheckAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No user is logged in');
      return;
    }

    debugPrint('Checking admin status for user: ${user.uid}');
    
    try {
      // Check user document
      final userSnapshot = await _database.ref('users/${user.uid}').get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        debugPrint('User data found:');
        debugPrint('isAdmin: ${userData['isAdmin']}');
        debugPrint('name: ${userData['name']}');
        debugPrint('email: ${userData['email']}');
      } else {
        debugPrint('No user document found');
      }

      // Check admin document
      final adminSnapshot = await _database.ref('admins/${user.uid}').get();
      if (adminSnapshot.exists) {
        debugPrint('Admin document exists');
        final adminData = adminSnapshot.value as Map<dynamic, dynamic>;
        debugPrint('Admin data:');
        debugPrint(adminData.toString());
      } else {
        debugPrint('No admin document found');
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  // Create time slots for a date
  Future<bool> createTimeSlotsForDate(DateTime date, List<String> selectedTimes) async {
    if (!_isAdmin) return false;

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Check existing slots
      final existingSlots = await _database.ref('timeSlots')
          .orderByChild('dateStr')
          .equalTo(dateStr)
          .get();

      final existingTimes = existingSlots.exists ? 
        (existingSlots.value as Map<dynamic, dynamic>).entries
          .map((entry) => (entry.value as Map<dynamic, dynamic>)['time'] as String)
          .toList() : [];

      final newTimes = selectedTimes.where((time) => !existingTimes.contains(time)).toList();

      for (var time in newTimes) {
        final slotId = DateTime.now().millisecondsSinceEpoch.toString();
        await _database.ref('timeSlots/$slotId').set({
          'id': slotId,
          'date': date.toIso8601String(),
          'dateStr': dateStr,
          'time': time,
          'status': 'available',
          'createdAt': ServerValue.timestamp,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error creating time slots: $e');
      _error = 'Failed to create time slots';
      return false;
    }
  }

  // Delete a time slot
  Future<bool> deleteTimeSlot(String slotId) async {
    if (!_isAdmin) return false;

    try {
      final slotSnapshot = await _database.ref('timeSlots/$slotId').get();
      if (!slotSnapshot.exists) {
        _error = 'Time slot not found';
        return false;
      }

      final slotData = slotSnapshot.value as Map<dynamic, dynamic>;
      if (slotData['status'] == 'booked') {
        _error = 'Cannot delete a booked time slot';
        return false;
      }

      await _database.ref('timeSlots/$slotId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting time slot: $e');
      _error = 'Failed to delete time slot';
      return false;
    }
  }

  // Promote user to admin
  Future<bool> promoteToAdmin(String userId) async {
    if (!_isAdmin) return false;

    try {
      final userSnapshot = await _database.ref('users/$userId').get();
      if (!userSnapshot.exists) {
        _error = 'User not found';
        return false;
      }

      await _database.ref('users/$userId').update({'isAdmin': true});
      return true;
    } catch (e) {
      debugPrint('Error promoting user to admin: $e');
      _error = 'Failed to promote user to admin';
      return false;
    }
  }

  // Add a new service type
  Future<bool> addServiceType(service_models.ServiceTypeModel serviceType) async {
    if (!_isAdmin) return false;

    try {
      final typeId = serviceType.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : serviceType.id;
      await _database.ref('serviceTypes/$typeId').set(serviceType.toJson());
      return true;
    } catch (e) {
      debugPrint('Error adding service type: $e');
      _error = 'Failed to add service type';
      return false;
    }
  }

  // Update a service type
  Future<bool> updateServiceType(service_models.ServiceTypeModel serviceType) async {
    if (!_isAdmin) return false;

    try {
      await _database.ref('serviceTypes/${serviceType.id}').update(serviceType.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating service type: $e');
      _error = 'Failed to update service type';
      return false;
    }
  }

  // Delete a service type
  Future<bool> deleteServiceType(String typeId) async {
    if (!_isAdmin) return false;

    try {
      // Check if any services use this type
      final servicesSnapshot = await _database.ref('services')
          .orderByChild('typeId')
          .equalTo(typeId)
          .get();

      if (servicesSnapshot.exists) {
        _error = 'Cannot delete service type that is being used by services';
        return false;
      }

      await _database.ref('serviceTypes/$typeId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting service type: $e');
      _error = 'Failed to delete service type';
      return false;
    }
  }
}
