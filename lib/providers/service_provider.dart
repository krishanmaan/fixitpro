import 'package:flutter/material.dart';
import 'package:fixitpro/models/service_model.dart';
import 'package:fixitpro/services/database_service.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';

class ServiceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
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
    notifyListeners();
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
        // First load service types
        await _firebaseService.safeRealtimeDatabaseOperation<void>(() async {
          final snapshot = await _database.ref('serviceTypes').get();

          if (!snapshot.exists) {
            _serviceTypes = ServiceTypeModel.defaults;
          } else {
            final typesData = snapshot.value as Map<dynamic, dynamic>;
            _serviceTypes = typesData.entries.map((entry) {
              final data = entry.value as Map<dynamic, dynamic>;
              return ServiceTypeModel.fromJson({
                ...Map<String, dynamic>.from(data),
                'id': entry.key,
              });
            }).toList();
          }
        }, null);

        // Then load services
        await _firebaseService.safeRealtimeDatabaseOperation<void>(() async {
          final snapshot = await _database.ref('services').get();
          
          if (snapshot.exists) {
            final servicesData = snapshot.value as Map<dynamic, dynamic>;
            _services = servicesData.entries.map((entry) {
              final data = entry.value as Map<dynamic, dynamic>;
              final serviceData = Map<String, dynamic>.from(data);
              
              // Ensure type is properly set
              if (serviceData['type'] is String) {
                // Convert legacy type string to ServiceTypeModel
                final typeId = serviceData['type'] as String;
                final serviceType = _serviceTypes.firstWhere(
                  (type) => type.id == typeId,
                  orElse: () => ServiceTypeModel.defaults.first,
                );
                serviceData['type'] = serviceType.toJson();
              }

              return ServiceModel.fromJson({
                ...serviceData,
                'id': entry.key,
              });
            }).toList();

            // Sort services by title
            _services.sort((a, b) => a.title.compareTo(b.title));
          } else {
            _services = [];
          }
        }, null);

        // Save to local storage for offline access
        await _saveServicesToLocalStorage();
      } else {
        // Load from local storage in offline mode
        await _loadServicesFromLocalStorage();
      }

      _hasLoadedOnce = true;
      _lastLoadTime = now;
    } catch (e) {
      debugPrint('Error loading services: $e');
      _error = 'Failed to load services';

      // Try to load from local storage as fallback
      await _loadServicesFromLocalStorage();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Create a new service
  Future<bool> createService(ServiceModel service) async {
    _setLoading(true);
    _error = null;

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Save to Realtime Database
        await _database.ref('services/${service.id}').set(service.toJson());

        // Add to local list
        _services.add(service);
        _services.sort((a, b) => a.title.compareTo(b.title));

        // Save to local storage
        await _saveServicesToLocalStorage();

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = 'Cannot create service in offline mode';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error creating service: $e');
      _error = 'Failed to create service';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update an existing service
  Future<bool> updateService(ServiceModel service) async {
    _setLoading(true);
    _error = null;

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Update in Realtime Database
        await _database.ref('services/${service.id}').update(service.toJson());

        // Update local list
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          _services[index] = service;
          _services.sort((a, b) => a.title.compareTo(b.title));
          await _saveServicesToLocalStorage();
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = 'Cannot update service in offline mode';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error updating service: $e');
      _error = 'Failed to update service';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete a service
  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    _error = null;

    try {
      final hasFirebaseAccess = await _checkFirebasePermissions();

      if (hasFirebaseAccess) {
        // Delete from Realtime Database
        await _database.ref('services/$serviceId').remove();

        // Remove from local list
        _services.removeWhere((s) => s.id == serviceId);
        await _saveServicesToLocalStorage();

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = 'Cannot delete service in offline mode';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting service: $e');
      _error = 'Failed to delete service';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Select a service
  void selectService(ServiceModel service) {
    _selectedService = service;
    _selectedDesign = null;
    _selectedTier = TierType.basic;
    notifyListeners();
  }

  // Select a material design
  void selectDesign(MaterialDesign? design) {
    _selectedDesign = design;
    notifyListeners();
  }

  // Select a tier
  void selectTier(TierType tier) {
    _selectedTier = tier;
    notifyListeners();
  }

  // Set area
  void setArea(double area) {
    _area = area;
    notifyListeners();
  }

  // Get selected tier pricing
  TierPricing? getSelectedTierPricing() {
    if (_selectedService == null) return null;

    return _selectedService!.tiers.firstWhere(
      (tier) => tier.tier == _selectedTier,
      orElse: () => _selectedService!.tiers.first,
    );
  }

  // Calculate total price based on current selections
  double calculateTotalPrice() {
    if (_selectedService == null) return 0.0;

    // Get the selected tier pricing
    TierPricing? selectedTierPricing = getSelectedTierPricing();

    if (selectedTierPricing == null) return 0.0;

    double basePrice = selectedTierPricing.price;
    double materialPrice = _selectedDesign?.pricePerUnit ?? 0.0;
    double visitCharge = selectedTierPricing.visitCharge;

    return (basePrice * _area) + (materialPrice * _area) + visitCharge;
  }
}
