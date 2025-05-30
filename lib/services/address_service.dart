import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:flutter/material.dart';

/// Service class to handle address-related Firestore operations
class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stream of user addresses for real-time updates
  Stream<List<SavedAddress>> getAddressesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return empty stream if no user is logged in
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => _convertSnapshotToAddresses(snapshot));
  }

  /// Helper method to convert Firestore snapshot to List<SavedAddress>
  List<SavedAddress> _convertSnapshotToAddresses(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SavedAddress(
        id: doc.id,
        label: data['label'] ?? 'Unnamed',
        address: data['address'] ?? 'No address',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// Add a new address or update an existing one
  Future<bool> saveAddress(SavedAddress address) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Save to Firestore addresses subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(address.id)
          .set({
            'label': address.label,
            'address': address.address,
            'latitude': address.latitude,
            'longitude': address.longitude,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Also update user document's savedAddresses field using a transaction
      await _updateUserSavedAddresses(user.uid, address, isDelete: false);

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

      // First, get the address to make sure we have its data
      final addressDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .doc(addressId)
              .get();

      if (!addressDoc.exists) return false;

      final addressData = addressDoc.data()!;
      final address = SavedAddress(
        id: addressId,
        label: addressData['label'] ?? 'Unnamed',
        address: addressData['address'] ?? 'No address',
        latitude: (addressData['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (addressData['longitude'] as num?)?.toDouble() ?? 0.0,
      );

      // Delete from addresses subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

      // Also update user document's savedAddresses field
      await _updateUserSavedAddresses(user.uid, address, isDelete: true);

      return true;
    } catch (e) {
      debugPrint('Error deleting address: $e');
      return false;
    }
  }

  /// Update the savedAddresses array in the user document
  Future<void> _updateUserSavedAddresses(
    String userId,
    SavedAddress address, {
    required bool isDelete,
  }) async {
    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return;

      // Convert to UserModel to work with the data
      final userData = userDoc.data() as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      // Update addresses list
      List<SavedAddress> updatedAddresses = [];

      if (isDelete) {
        // Remove the address
        updatedAddresses =
            user.savedAddresses.where((a) => a.id != address.id).toList();
      } else {
        // Add or update the address
        final existingIndex = user.savedAddresses.indexWhere(
          (a) => a.id == address.id,
        );

        if (existingIndex >= 0) {
          // Update existing address
          updatedAddresses = List.from(user.savedAddresses);
          updatedAddresses[existingIndex] = address;
        } else {
          // Add new address
          updatedAddresses = [...user.savedAddresses, address];
        }
      }

      // Update user document
      final updatedUser = user.copyWith(savedAddresses: updatedAddresses);
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updatedUser.toJson());
    } catch (e) {
      debugPrint('Error updating user saved addresses: $e');
      // Don't throw, as this is a secondary operation
    }
  }

  /// Get the default address (first in the list) if available
  Future<SavedAddress?> getDefaultAddress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .orderBy('updatedAt', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      return SavedAddress(
        id: doc.id,
        label: data['label'] ?? 'Default',
        address: data['address'] ?? 'No address',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('Error getting default address: $e');
      return null;
    }
  }
}
