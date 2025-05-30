import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:flutter/material.dart';

/// Service class to handle address-related database operations
class AddressService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stream of user addresses for real-time updates
  Stream<List<SavedAddress>> getAddressesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return empty stream if no user is logged in
      return Stream.value([]);
    }

    return _database
        .ref('users/${user.uid}/addresses')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return [];
          
          final addressesData = event.snapshot.value as Map<dynamic, dynamic>;
          final List<SavedAddress> addresses = [];
          
          addressesData.forEach((key, value) {
            final address = SavedAddress(
              id: key,
              label: value['label'] ?? 'Unnamed',
              address: value['address'] ?? 'No address',
              latitude: (value['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (value['longitude'] as num?)?.toDouble() ?? 0.0,
            );
            addresses.add(address);
          });
          
          // Return addresses as is, without sorting
          return addresses;
        });
  }

  /// Add a new address or update an existing one
  Future<bool> saveAddress(SavedAddress address) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Save to Realtime Database addresses path
      await _database
          .ref('users/${user.uid}/addresses/${address.id}')
          .set({
            'label': address.label,
            'address': address.address,
            'latitude': address.latitude,
            'longitude': address.longitude,
            'updatedAt': ServerValue.timestamp,
          });

      return true;
    } catch (e) {
      debugPrint('Error saving address: $e');
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Delete from Realtime Database
      await _database
          .ref('users/${user.uid}/addresses/$addressId')
          .remove();

      return true;
    } catch (e) {
      debugPrint('Error deleting address: $e');
      return false;
    }
  }

  /// Get all addresses for a user
  Future<List<SavedAddress>> getUserAddresses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _database
          .ref('users/${user.uid}/addresses')
          .get();

      if (!snapshot.exists) return [];

      final addressesData = snapshot.value as Map<dynamic, dynamic>;
      final List<SavedAddress> addresses = [];

      addressesData.forEach((key, value) {
        final address = SavedAddress(
          id: key,
          label: value['label'] ?? 'Unnamed',
          address: value['address'] ?? 'No address',
          latitude: (value['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (value['longitude'] as num?)?.toDouble() ?? 0.0,
        );
        addresses.add(address);
      });

      // Return addresses as is, without sorting
      return addresses;
    } catch (e) {
      debugPrint('Error getting user addresses: $e');
      return [];
    }
  }
}
