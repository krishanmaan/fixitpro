// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:fixitpro/main.dart';
import 'package:fixitpro/services/firebase_service.dart';
import 'package:fixitpro/models/booking_model.dart';

// Mock FirebaseService for testing
class MockFirebaseService implements IFirebaseService {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  late FirebaseStorage _storage;
  final bool _isConnected = true;

  @override
  bool get isOfflineMode => false;

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<bool> checkConnectivity() async {
    return _isConnected;
  }

  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  FirebaseAuth get auth => _auth;

  @override
  FirebaseStorage get storage => _storage;

  @override
  Future<bool> checkCollection(String collection) async {
    return true;
  }

  @override
  Future<bool> checkAdminAccess() async {
    return false;
  }

  @override
  Future<bool> isTimeSlotAvailable(String slotId) async {
    return true;
  }

  @override
  Future<bool> markTimeSlotAsBooked(String slotId, String bookingId) async {
    return true;
  }

  @override
  Future<T> safeFirestoreOperation<T>(
    Future<T> Function() operation,
    T defaultValue,
  ) async {
    try {
      return await operation();
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  void setOfflineMode(bool isOffline) {
    // Mock implementation - do nothing
  }

  Future<DocumentReference> saveBooking(BookingModel booking) async {
    return _firestore.collection('bookings').doc('mock-id');
  }

  Future<void> updateBooking(BookingModel booking) async {
    // Mock implementation
    return;
  }

  Future<void> cancelBooking(String bookingId) async {
    // Mock implementation
    return;
  }

  @override
  Future<List<BookingModel>> loadBookings(String userId) async {
    return []; // Mock implementation - empty list
  }

  Future<Map<String, dynamic>> getServiceProviderById(String id) async {
    return {
      'id': 'provider-1',
      'name': 'Test Provider',
      'specialization': 'All Services',
    };
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock FirebaseService
    final mockFirebaseService = MockFirebaseService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(firebaseInitialized: true, firebaseService: mockFirebaseService),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
