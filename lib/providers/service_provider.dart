import 'package:flutter/material.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/services/database_service.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  List<ServiceModel> _services = [];
  List<ServiceTypeModel> _serviceTypes = [];
  ServiceModel? _selectedService;
  MaterialDesign? _selectedDesign;
  TierType _selectedTier = TierType.basic;
  double _area = 100.0; // Default area
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedOnce = false;
  DateTime? _lastLoadTime;
  bool _isOfflineMode = false;

  // Getters
  List<ServiceModel> get services => _services;
  List<ServiceTypeModel> get serviceTypes => _serviceTypes;
  ServiceModel? get selectedService => _selectedService;
  MaterialDesign? get selectedDesign => _selectedDesign;
  TierType get selectedTier => _selectedTier;
  double get area => _area;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoadedOnce;
  bool get isOfflineMode => _isOfflineMode;

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  // Check Firebase access permissions using improved FirebaseService
  Future<bool> _checkFirebasePermissions() async {
    final canAccess = await _firebaseService.checkCollection('services');
    _isOfflineMode = !canAccess;
    return canAccess;
  }

  // Save services to local storage for offline mode
  Future<void> _saveServicesToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final servicesJson =
          _services.map((service) => service.toJson()).toList();
      await prefs.setString('cached_services', jsonEncode(servicesJson));

      // Also save service types
      final typesJson = _serviceTypes.map((type) => type.toJson()).toList();
      await prefs.setString('cached_service_types', jsonEncode(typesJson));
    } catch (e) {
      debugPrint('Error saving services to local storage: $e');
    }
  }

  // Load services from local storage for offline mode
  Future<void> _loadServicesFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load services
      final servicesJson = prefs.getString('cached_services');
      if (servicesJson != null && servicesJson.isNotEmpty) {
        final servicesData = jsonDecode(servicesJson) as List;
        _services =
            servicesData
                .map(
                  (data) => ServiceModel.fromJson(data as Map<String, dynamic>),
                )
                .toList();
      }

      // Load service types
      final typesJson = prefs.getString('cached_service_types');
      if (typesJson != null && typesJson.isNotEmpty) {
        final typesData = jsonDecode(typesJson) as List;
        _serviceTypes =
            typesData
                .map(
                  (data) =>
                      ServiceTypeModel.fromJson(data as Map<String, dynamic>),
                )
                .toList();
      } else {
        _serviceTypes = ServiceTypeModel.defaults;
      }

      _hasLoadedOnce = true;
      _lastLoadTime = DateTime.now();
    } catch (e) {
      debugPrint('Error loading services from local storage: $e');
      _serviceTypes = ServiceTypeModel.defaults;
    }
  }

  // Get services by legacy ServiceType enum
  List<ServiceModel> getServicesByType(ServiceType type) {
    ServiceTypeModel typeModel;

    // Map enum to ServiceTypeModel
    switch (type) {
      case ServiceType.repair:
        typeModel = ServiceTypeModel.repair;
        break;
      case ServiceType.installation:
        typeModel = ServiceTypeModel.installation;
        break;
      case ServiceType.installationWithMaterial:
        typeModel = ServiceTypeModel.installationWithMaterial;
        break;
    }

    return _services
        .where((service) => service.type.id == typeModel.id)
        .toList();
  }

  // Get services by service type ID
  List<ServiceModel> getServicesByTypeId(String typeId) {
    return _services.where((service) => service.type.id == typeId).toList();
  }

  // Get all service types with services
  List<ServiceTypeModel> getServiceTypesWithServices() {
    // Get unique service types from services
    final Set<String> typeIds =
        _services.map((service) => service.type.id).toSet();

    // Return service types that have services
    return _serviceTypes.where((type) => typeIds.contains(type.id)).toList();
  }

  // Get services by category
  List<ServiceModel> getServicesByCategory(String categoryId) {
    return _services
        .where((service) => service.categoryId == categoryId)
        .toList();
  }

  // Load all services and service types
  Future<void> loadServices({bool forceRefresh = false}) async {
    // Always refresh if services list is empty - ensures admin added services are always shown
    if (_services.isEmpty) {
      forceRefresh = true;
    }

    // If services are already loaded and forceRefresh is false,
    // and it's been less than 5 minutes since the last load, return immediately
    final now = DateTime.now();
    if (!forceRefresh &&
        _hasLoadedOnce &&
        _services.isNotEmpty &&
        _lastLoadTime != null &&
        now.difference(_lastLoadTime!).inMinutes < 5) {
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      // Check Firebase permissions
      bool hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // First load service types using safeFirestoreOperation
        await _firebaseService.safeFirestoreOperation<void>(() async {
          final snapshot = await _firestore.collection('serviceTypes').get();

          if (snapshot.docs.isEmpty) {
            _serviceTypes = ServiceTypeModel.defaults;
          } else {
            _serviceTypes =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return ServiceTypeModel.fromJson({...data, 'id': doc.id});
                }).toList();
          }
        }, null);

        // Then load services using database service
        try {
          final List<ServiceModel> firestoreServices =
              await _databaseService.getAllServices();
          _services = firestoreServices;
          _hasLoadedOnce = true;
          _lastLoadTime = now;
        } catch (e) {
          // If there's an error, fall back to cached services
          debugPrint('Error loading services: $e, using cached data');
          await _loadServicesFromLocalStorage();
        }

        // Cache the results for offline use
        await _saveServicesToLocalStorage();
      } else {
        // In offline mode, load from local storage
        debugPrint('Working in offline mode, loading cached services');
        await _loadServicesFromLocalStorage();
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
      _error = 'Failed to load services from server.';

      // Try to load from local storage
      await _loadServicesFromLocalStorage();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Select a service
  void selectService(ServiceModel service) {
    _selectedService = service;
    // Reset other selections
    _selectedDesign = null;
    _selectedTier = TierType.basic;
    notifyListeners();
  }

  // Select a design
  void selectDesign(MaterialDesign? design) {
    _selectedDesign = design;
    notifyListeners();
  }

  // Select a tier
  void selectTier(TierType tier) {
    _selectedTier = tier;
    notifyListeners();
  }

  // Get tier pricing for selected service and tier
  TierPricing? getSelectedTierPricing() {
    if (_selectedService == null) return null;

    try {
      return _selectedService!.tiers.firstWhere(
        (tier) => tier.tier == _selectedTier,
        orElse: () => _selectedService!.tiers.first,
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate total price based on selected tier, material, and area
  double calculateTotalPrice(double area) {
    _area = area; // Store area for future reference
    double totalPrice = 0;

    // Calculate base price from tier
    final selectedTierPricing = getSelectedTierPricing();
    if (selectedTierPricing != null) {
      totalPrice += selectedTierPricing.price * area;
    }

    // Add material price if applicable
    if (_selectedService?.includesMaterial == true && _selectedDesign != null) {
      totalPrice += _selectedDesign!.pricePerUnit * area;
    }

    return totalPrice;
  }

  // Admin Functions
  // Add a new service
  Future<bool> addService(ServiceModel service) async {
    _setLoading(true);
    _error = null;

    try {
      // Check if we have Firebase access
      bool hasFirebaseAccess = await _checkFirebasePermissions();

      // Generate a new service with UUID
      final String serviceId = const Uuid().v4();
      final newService = ServiceModel(
        id: serviceId,
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

      // Try to save to Firestore if we have access
      if (hasFirebaseAccess) {
        try {
          await _databaseService.addService(service);
        } catch (e) {
          debugPrint('Error in database service when adding service: $e');
          _isOfflineMode = true;
        }
      }

      // Always update local state
      _services.add(newService);

      return true;
    } catch (e) {
      debugPrint('Error adding service: $e');
      _error = 'Failed to add service. Service saved locally only.';
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update a service
  Future<bool> updateService(ServiceModel service) async {
    _setLoading(true);
    _error = null;

    try {
      // Check if we have Firebase access
      bool hasFirebaseAccess = await _checkFirebasePermissions();

      // Always update local state first
      int index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = service;
      }

      // If this is the selected service, update that too
      if (_selectedService != null && _selectedService!.id == service.id) {
        _selectedService = service;
      }

      // Try to update in Firestore if we have access
      if (hasFirebaseAccess) {
        try {
          await _databaseService.updateService(service);
        } catch (e) {
          debugPrint('Error in database service when updating service: $e');
          _isOfflineMode = true;
          // We already updated local state, so continue
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      _error = 'Failed to update service in server. Changes saved locally.';
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Delete a service
  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    _error = null;

    try {
      // Check if we have Firebase access
      bool hasFirebaseAccess = await _checkFirebasePermissions();

      // Try to delete from Firestore if we have access
      if (hasFirebaseAccess) {
        try {
          await _databaseService.deleteService(serviceId);
        } catch (e) {
          debugPrint('Error in database service when deleting service: $e');
          _isOfflineMode = true;
          // Continue to remove from local state
        }
      }

      // Always update local state
      _services.removeWhere((service) => service.id == serviceId);

      // If this was the selected service, clear selection
      if (_selectedService != null && _selectedService!.id == serviceId) {
        _selectedService = null;
        _selectedDesign = null;
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      _error = 'Failed to delete service from server. Removed locally only.';

      // Still remove from local state to maintain consistency
      _services.removeWhere((service) => service.id == serviceId);

      if (_selectedService != null && _selectedService!.id == serviceId) {
        _selectedService = null;
        _selectedDesign = null;
      }

      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Add tier to a service
  Future<bool> addTierToService(String serviceId, TierPricing tier) async {
    _setLoading(true);
    _error = null;

    try {
      // Find the service in our local list
      int serviceIndex = _services.indexWhere((s) => s.id == serviceId);
      if (serviceIndex == -1) {
        throw Exception('Service not found');
      }

      // Generate unique ID for tier
      String tierId = const Uuid().v4();
      TierPricing newTier = TierPricing(
        id: tierId,
        serviceId: serviceId,
        tier: tier.tier,
        price: tier.price,
        warrantyMonths: tier.warrantyMonths,
        features: tier.features,
      );

      // Update local service
      ServiceModel service = _services[serviceIndex];
      List<TierPricing> updatedTiers = [...service.tiers, newTier];
      ServiceModel updatedService = service.copyWith(tiers: updatedTiers);

      // Update in local list
      _services[serviceIndex] = updatedService;

      // If this is the selected service, update that too
      if (_selectedService != null && _selectedService!.id == serviceId) {
        _selectedService = updatedService;
      }

      // Check if we have Firebase access and try to update
      bool hasFirebaseAccess = await _checkFirebasePermissions();
      if (hasFirebaseAccess) {
        try {
          await _databaseService.addTierToService(serviceId, newTier);
        } catch (e) {
          debugPrint('Error in database service when adding tier: $e');
          _isOfflineMode = true;
          // We already updated local state, so continue
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error adding tier: $e');
      _error = 'Failed to add tier to server. Changes saved locally.';
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Add design to a service
  Future<bool> addDesignToService(
    String serviceId,
    MaterialDesign design,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      // Find the service in our local list
      int serviceIndex = _services.indexWhere((s) => s.id == serviceId);
      if (serviceIndex == -1) {
        throw Exception('Service not found');
      }

      // Generate unique ID for design
      String designId = const Uuid().v4();
      MaterialDesign newDesign = MaterialDesign(
        id: designId,
        serviceId: serviceId,
        imageUrl: design.imageUrl,
        name: design.name,
        pricePerUnit: design.pricePerUnit,
      );

      // Update local service
      ServiceModel service = _services[serviceIndex];
      List<MaterialDesign> updatedDesigns = [...service.designs, newDesign];
      ServiceModel updatedService = service.copyWith(designs: updatedDesigns);

      // Update in local list
      _services[serviceIndex] = updatedService;

      // If this is the selected service, update that too
      if (_selectedService != null && _selectedService!.id == serviceId) {
        _selectedService = updatedService;
      }

      // Check if we have Firebase access and try to update
      bool hasFirebaseAccess = await _checkFirebasePermissions();
      if (hasFirebaseAccess) {
        try {
          await _databaseService.addDesignToService(serviceId, newDesign);
        } catch (e) {
          debugPrint('Error in database service when adding design: $e');
          _isOfflineMode = true;
          // We already updated local state, so continue
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error adding design: $e');
      _error = 'Failed to add design to server. Changes saved locally.';
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Reset error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset selections
  void resetSelections() {
    _selectedService = null;
    _selectedDesign = null;
    _selectedTier = TierType.basic;
    notifyListeners();
  }
}
