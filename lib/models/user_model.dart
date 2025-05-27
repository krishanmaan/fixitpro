class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<SavedAddress> savedAddresses;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.savedAddresses = const [],
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<SavedAddress> addresses = [];
    if (json['savedAddresses'] != null) {
      addresses = List<SavedAddress>.from(
        json['savedAddresses'].map((address) => SavedAddress.fromJson(address)),
      );
    }

    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      savedAddresses: addresses,
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'savedAddresses':
          savedAddresses.map((address) => address.toJson()).toList(),
      'isAdmin': isAdmin,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    List<SavedAddress>? savedAddresses,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class SavedAddress {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'],
      label: json['label'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
