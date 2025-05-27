import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Service for handling file storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Get storage reference for a given path
  Reference getStorageRef(String path) {
    return _storage.ref().child(path);
  }

  /// Get download URL for a file
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      return null;
    }
  }

  /// Upload a file to Firebase Storage
  Future<String> uploadFile(File file, String folderPath) async {
    try {
      // Generate a unique file name
      final fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '$folderPath/$fileName';

      // Create a reference to the storage location
      final storageRef = _storage.ref().child(filePath);

      // Upload the file
      final uploadTask = storageRef.putFile(file);

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload a profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    return uploadFile(imageFile, 'profile_images/$userId');
  }

  /// Upload a service image
  Future<String> uploadServiceImage(File imageFile) async {
    return uploadFile(imageFile, 'service_images');
  }

  /// Upload a review image
  Future<String> uploadReviewImage(File imageFile, String bookingId) async {
    return uploadFile(imageFile, 'review_images/$bookingId');
  }

  /// Upload a material design image
  Future<String> uploadMaterialDesignImage(
    File imageFile,
    String serviceId,
  ) async {
    return uploadFile(imageFile, 'material_designs/$serviceId');
  }

  /// Upload a booking image (proof of work)
  Future<String> uploadBookingImage(File imageFile, String bookingId) async {
    return uploadFile(imageFile, 'booking_images/$bookingId');
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Create a reference from the file URL
      final ref = _storage.refFromURL(fileUrl);

      // Delete the file
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Get metadata for a file
  Future<Map<String, dynamic>?> getFileMetadata(String fileUrl) async {
    try {
      // Create a reference from the file URL
      final ref = _storage.refFromURL(fileUrl);

      // Get metadata
      final metadata = await ref.getMetadata();

      return {
        'name': metadata.name,
        'path': metadata.fullPath,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'createdAt': metadata.timeCreated,
        'updatedAt': metadata.updated,
      };
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  /// List all files in a folder
  Future<List<String>> listFiles(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();

      List<String> urls = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }
}
