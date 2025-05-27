import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String name;
  final String email;
  final bool isSuperAdmin;
  final DateTime createdAt;
  final String? imageUrl;
  final String? phoneNumber;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    this.isSuperAdmin = false,
    required this.createdAt,
    this.imageUrl,
    this.phoneNumber,
  });

  // Create a copy of the admin with modified fields
  AdminModel copyWith({
    String? id,
    String? name,
    String? email,
    bool? isSuperAdmin,
    DateTime? createdAt,
    String? imageUrl,
    String? phoneNumber,
  }) {
    return AdminModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  // Convert from JSON
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      imageUrl: json['imageUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isSuperAdmin': isSuperAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
    };
  }
}
