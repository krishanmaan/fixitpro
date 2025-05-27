import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for managing repair/maintenance services in the application
class ServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all service categories as a stream for real-time updates
  Stream<List<ServiceCategory>> getCategoriesStream() {
    return _firestore
        .collection('serviceCategories')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ServiceCategory.fromJson(
                      doc.data(),
                    ),
                  )
                  .toList(),
        );
  }

  /// Get all service categories
  Future<List<ServiceCategory>> getCategories() async {
    try {
      final snapshot =
          await _firestore
              .collection('serviceCategories')
              .orderBy('order')
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                ServiceCategory.fromJson(doc.data()),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting service categories: $e');
      return [];
    }
  }

  /// Get services by category as a stream for real-time updates
  Stream<List<Service>> getServicesByCategoryStream(String categoryId) {
    Query query = _firestore.collection('services');

    // Filter by category if not "all"
    if (categoryId.toLowerCase() != 'all') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Service.fromJson(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  /// Get services by category
  Future<List<Service>> getServicesByCategory(String categoryId) async {
    try {
      Query query = _firestore.collection('services');

      // Filter by category if not "all"
      if (categoryId.toLowerCase() != 'all') {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.orderBy('name').get();

      return snapshot.docs
          .map((doc) => Service.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting services by category: $e');
      return [];
    }
  }

  /// Get all services as a stream for real-time updates
  Stream<List<Service>> getAllServicesStream() {
    return _firestore
        .collection('services')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Service.fromJson(doc.data()),
                  )
                  .toList(),
        );
  }

  /// Get all services
  Future<List<Service>> getAllServices() async {
    try {
      final snapshot =
          await _firestore.collection('services').orderBy('name').get();

      return snapshot.docs
          .map((doc) => Service.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all services: $e');
      return [];
    }
  }

  /// Get service by ID as a stream for real-time updates
  Stream<Service?> getServiceByIdStream(String serviceId) {
    return _firestore.collection('services').doc(serviceId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return Service.fromJson(doc.data()!);
      }
      return null;
    });
  }

  /// Get service by ID
  Future<Service?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();

      if (!doc.exists) {
        return null;
      }

      return Service.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting service by ID: $e');
      return null;
    }
  }

  /// Get featured services as a stream for real-time updates
  Stream<List<Service>> getFeaturedServicesStream() {
    return _firestore
        .collection('services')
        .where('isFeatured', isEqualTo: true)
        .orderBy('bookingCount', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Service.fromJson(doc.data()),
                  )
                  .toList(),
        );
  }

  /// Get featured services
  Future<List<Service>> getFeaturedServices() async {
    try {
      final snapshot =
          await _firestore
              .collection('services')
              .where('isFeatured', isEqualTo: true)
              .orderBy('bookingCount', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => Service.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting featured services: $e');
      return [];
    }
  }

  /// Search services by name or description
  Future<List<Service>> searchServices(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Get all services first (Firestore doesn't support text search directly)
      final services = await getAllServices();

      // Filter services client-side
      if (query.isNotEmpty) {
        return services.where((service) {
          final name = service.name.toLowerCase();
          final description = service.description.toLowerCase();
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              description.contains(searchQuery);
        }).toList();
      }

      return services;
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }

  /// Get material designs for a service as a stream for real-time updates
  Stream<List<MaterialDesign>> getMaterialDesignsForServiceStream(
    String serviceId,
  ) {
    return _firestore
        .collection('materialDesigns')
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('price')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => MaterialDesign.fromJson(
                      doc.data(),
                    ),
                  )
                  .toList(),
        );
  }

  /// Get material designs for a service
  Future<List<MaterialDesign>> getMaterialDesignsForService(
    String serviceId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('materialDesigns')
              .where('serviceId', isEqualTo: serviceId)
              .orderBy('price')
              .get();

      return snapshot.docs
          .map(
            (doc) =>
                MaterialDesign.fromJson(doc.data()),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting material designs: $e');
      return [];
    }
  }
}

/// Service Category model
class ServiceCategory {
  final String id;
  final String name;
  final String image;
  final int order;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.order,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image, 'order': order};
  }
}

/// Service model
class Service {
  final String id;
  final String name;
  final String description;
  final String image;
  final String categoryId;
  final String categoryName;
  final double basicPrice;
  final double standardPrice;
  final double premiumPrice;
  final double rating;
  final int reviewCount;
  final int bookingCount;
  final bool isFeatured;
  final List<String> inclusions;
  final Map<String, List<String>> tierInclusions;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.categoryId,
    required this.categoryName,
    required this.basicPrice,
    required this.standardPrice,
    required this.premiumPrice,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.bookingCount = 0,
    this.isFeatured = false,
    this.inclusions = const [],
    this.tierInclusions = const {},
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // Handle inclusions
    List<String> parseInclusions(dynamic inclusionsData) {
      if (inclusionsData == null) return [];
      if (inclusionsData is List) {
        return List<String>.from(inclusionsData);
      }
      return [];
    }

    // Handle tier inclusions
    Map<String, List<String>> parseTierInclusions(dynamic tierInclusionsData) {
      if (tierInclusionsData == null) return {};
      if (tierInclusionsData is Map) {
        return Map<String, List<String>>.from(
          tierInclusionsData.map(
            (key, value) =>
                MapEntry(key as String, List<String>.from(value as List)),
          ),
        );
      }
      return {};
    }

    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      basicPrice: (json['basicPrice'] as num).toDouble(),
      standardPrice: (json['standardPrice'] as num).toDouble(),
      premiumPrice: (json['premiumPrice'] as num).toDouble(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      bookingCount: json['bookingCount'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      inclusions: parseInclusions(json['inclusions']),
      tierInclusions: parseTierInclusions(json['tierInclusions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'basicPrice': basicPrice,
      'standardPrice': standardPrice,
      'premiumPrice': premiumPrice,
      'rating': rating,
      'reviewCount': reviewCount,
      'bookingCount': bookingCount,
      'isFeatured': isFeatured,
      'inclusions': inclusions,
      'tierInclusions': tierInclusions,
    };
  }
}

/// Material Design model
class MaterialDesign {
  final String id;
  final String serviceId;
  final String name;
  final String image;
  final double price;
  final String description;

  MaterialDesign({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
  });

  factory MaterialDesign.fromJson(Map<String, dynamic> json) {
    return MaterialDesign(
      id: json['id'],
      serviceId: json['serviceId'],
      name: json['name'],
      image: json['image'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'name': name,
      'image': image,
      'price': price,
      'description': description,
    };
  }
}
