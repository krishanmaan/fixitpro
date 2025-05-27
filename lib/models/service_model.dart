import 'package:flutter/material.dart' show debugPrint;

enum ServiceType { repair, installation, installationWithMaterial }

// Define a class for ServiceType instead of an enum to allow dynamic addition
class ServiceTypeModel {
  final String id;
  final String name;
  final String displayName;
  final bool includesMaterial;
  final String imageUrl; // URL for custom icon/logo

  ServiceTypeModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.includesMaterial = false,
    this.imageUrl = '', // Default empty string if no custom image
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      includesMaterial: json['includesMaterial'] ?? false,
      imageUrl: json['imageUrl'] ?? '', // Parse imageUrl from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'includesMaterial': includesMaterial,
      'imageUrl': imageUrl, // Include imageUrl in JSON
    };
  }

  // Define default service types for backwards compatibility
  static ServiceTypeModel get repair => ServiceTypeModel(
    id: 'repair',
    name: 'repair',
    displayName: 'Repair',
    includesMaterial: false,
    imageUrl: '', // Empty for default icon
  );

  static ServiceTypeModel get installation => ServiceTypeModel(
    id: 'installation',
    name: 'installation',
    displayName: 'Installation',
    includesMaterial: false,
    imageUrl: '', // Empty for default icon
  );

  static ServiceTypeModel get installationWithMaterial => ServiceTypeModel(
    id: 'installationWithMaterial',
    name: 'installationWithMaterial',
    displayName: 'Installation with Material',
    includesMaterial: true,
    imageUrl: '', // Empty for default icon
  );

  // Get default types for dropdown selection
  static List<ServiceTypeModel> get defaults => [
    repair,
    installation,
    installationWithMaterial,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum MeasurementUnit { sqft, inch }

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final ServiceTypeModel
  type; // Change from ServiceType enum to ServiceTypeModel
  final MeasurementUnit unit;
  final bool includesMaterial;
  final List<TierPricing> tiers;
  final List<MaterialDesign> designs;
  final String imageUrl;
  final String categoryId;

  ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.unit,
    this.includesMaterial = false,
    this.tiers = const [],
    this.designs = const [],
    required this.imageUrl,
    required this.categoryId,
  });

  ServiceModel copyWith({
    String? id,
    String? title,
    String? description,
    ServiceTypeModel? type,
    MeasurementUnit? unit,
    bool? includesMaterial,
    List<TierPricing>? tiers,
    List<MaterialDesign>? designs,
    String? imageUrl,
    String? categoryId,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      includesMaterial: includesMaterial ?? this.includesMaterial,
      tiers: tiers ?? this.tiers,
      designs: designs ?? this.designs,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Parse tiers
    List<TierPricing> tiers = [];
    if (json['tiers'] != null) {
      tiers = List<TierPricing>.from(
        json['tiers'].map((tier) => TierPricing.fromJson(tier)),
      );
    }

    // Parse designs if applicable
    List<MaterialDesign> designs = [];
    if (json['designs'] != null) {
      designs = List<MaterialDesign>.from(
        json['designs'].map((design) => MaterialDesign.fromJson(design)),
      );
    }

    // Parse service type from string to ServiceTypeModel
    ServiceTypeModel serviceType;
    try {
      // First check if it's a new style service type (object)
      if (json['type'] is Map<String, dynamic>) {
        serviceType = ServiceTypeModel.fromJson(
          json['type'] as Map<String, dynamic>,
        );
      } else if (json['type'] is String) {
        // It's an old style service type (string)
        final typeStr = json['type'] as String;
        switch (typeStr) {
          case 'repair':
            serviceType = ServiceTypeModel.repair;
            break;
          case 'installation':
            serviceType = ServiceTypeModel.installation;
            break;
          case 'installationWithMaterial':
            serviceType = ServiceTypeModel.installationWithMaterial;
            break;
          default:
            // Try to find the service type by name in the defaults
            final matchingDefault = ServiceTypeModel.defaults.firstWhere(
              (type) => type.name == typeStr,
              orElse: () => ServiceTypeModel.repair,
            );
            serviceType = matchingDefault;
        }
      } else {
        // Default to repair if type is missing or in unexpected format
        serviceType = ServiceTypeModel.repair;
      }
    } catch (e) {
      debugPrint('Error parsing service type: $e');
      // Default to repair if there's an error
      serviceType = ServiceTypeModel.repair;
    }

    return ServiceModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: serviceType,
      unit: MeasurementUnit.values.firstWhere(
        (e) => e.toString() == 'MeasurementUnit.${json['unit']}',
        orElse: () => MeasurementUnit.sqft,
      ),
      includesMaterial: json['includesMaterial'] ?? false,
      tiers: tiers,
      designs: designs,
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type':
          type.toJson(), // Store the full service type object instead of just the name
      'unit': unit.toString().split('.').last,
      'includesMaterial': includesMaterial,
      'tiers': tiers.map((tier) => tier.toJson()).toList(),
      'designs': designs.map((design) => design.toJson()).toList(),
      'imageUrl': imageUrl,
      'categoryId': categoryId,
    };
  }
}

enum TierType { basic, standard, premium }

class TierPricing {
  final String id;
  final String serviceId;
  final TierType tier;
  final double price;
  final int warrantyMonths;
  final List<String> features;
  final double visitCharge;

  TierPricing({
    required this.id,
    required this.serviceId,
    required this.tier,
    required this.price,
    required this.warrantyMonths,
    this.features = const [],
    this.visitCharge = 0.0,
  });

  factory TierPricing.fromJson(Map<String, dynamic> json) {
    List<String> featureList = [];
    if (json['features'] != null) {
      featureList = List<String>.from(json['features']);
    }

    return TierPricing(
      id: json['id'],
      serviceId: json['serviceId'],
      tier: TierType.values.firstWhere(
        (e) => e.toString() == 'TierType.${json['tier']}',
        orElse: () => TierType.basic,
      ),
      price: json['price'].toDouble(),
      warrantyMonths: json['warrantyMonths'],
      features: featureList,
      visitCharge:
          json['visitCharge'] != null ? json['visitCharge'].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'tier': tier.toString().split('.').last,
      'price': price,
      'warrantyMonths': warrantyMonths,
      'features': features,
      'visitCharge': visitCharge,
    };
  }
}

class MaterialDesign {
  final String id;
  final String serviceId;
  final String imageUrl;
  final String name;
  final double pricePerUnit;

  MaterialDesign({
    required this.id,
    required this.serviceId,
    required this.imageUrl,
    required this.name,
    required this.pricePerUnit,
  });

  factory MaterialDesign.fromJson(Map<String, dynamic> json) {
    return MaterialDesign(
      id: json['id'],
      serviceId: json['serviceId'],
      imageUrl: json['imageUrl'],
      name: json['name'],
      pricePerUnit: json['pricePerUnit'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'imageUrl': imageUrl,
      'name': name,
      'pricePerUnit': pricePerUnit,
    };
  }
}
