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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toJson(),
      'unit': unit.toString().split('.').last,
      'includesMaterial': includesMaterial,
      'tiers': tiers.map((tier) => tier.toJson()).toList(),
      'designs': designs.map((design) => design.toJson()).toList(),
      'imageUrl': imageUrl,
      'categoryId': categoryId,
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Parse tiers
    List<TierPricing> tiers = [];
    if (json['tiers'] != null) {
      if (json['tiers'] is List) {
        tiers = List<TierPricing>.from(
          (json['tiers'] as List).map((tier) => TierPricing.fromJson(
            tier is Map ? Map<String, dynamic>.from(tier) : tier,
          )),
        );
      } else if (json['tiers'] is Map) {
        tiers = (json['tiers'] as Map).entries.map((entry) {
          final tierData = entry.value;
          return TierPricing.fromJson(
            tierData is Map ? Map<String, dynamic>.from(tierData) : tierData,
          );
        }).toList();
      }
    }

    // Parse designs if applicable
    List<MaterialDesign> designs = [];
    if (json['designs'] != null) {
      if (json['designs'] is List) {
        designs = List<MaterialDesign>.from(
          (json['designs'] as List).map((design) => MaterialDesign.fromJson(
            design is Map ? Map<String, dynamic>.from(design) : design,
          )),
        );
      } else if (json['designs'] is Map) {
        designs = (json['designs'] as Map).entries.map((entry) {
          final designData = entry.value;
          return MaterialDesign.fromJson(
            designData is Map ? Map<String, dynamic>.from(designData) : designData,
          );
        }).toList();
      }
    }

    // Parse service type
    ServiceTypeModel serviceType;
    try {
      if (json['type'] is Map) {
        // New style: type is a full object
        serviceType = ServiceTypeModel.fromJson(
          Map<String, dynamic>.from(json['type'] as Map),
        );
      } else if (json['type'] is String) {
        // Old style: type is a string ID
        final typeStr = json['type'] as String;
        serviceType = ServiceTypeModel(
          id: typeStr,
          name: typeStr,
          displayName: typeStr.substring(0, 1).toUpperCase() + typeStr.substring(1),
          includesMaterial: typeStr == 'installationWithMaterial',
        );
      } else {
        // Default to repair if type is missing or invalid
        serviceType = ServiceTypeModel.repair;
      }
    } catch (e) {
      debugPrint('Error parsing service type: $e');
      serviceType = ServiceTypeModel.repair;
    }

    // Parse measurement unit
    MeasurementUnit unit;
    try {
      if (json['unit'] is String) {
        final unitStr = json['unit'] as String;
        unit = MeasurementUnit.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == unitStr.toLowerCase(),
          orElse: () => MeasurementUnit.sqft,
        );
      } else {
        unit = MeasurementUnit.sqft;
      }
    } catch (e) {
      debugPrint('Error parsing measurement unit: $e');
      unit = MeasurementUnit.sqft;
    }

    return ServiceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: serviceType,
      unit: unit,
      includesMaterial: json['includesMaterial'] ?? false,
      tiers: tiers,
      designs: designs,
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? '',
    );
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
