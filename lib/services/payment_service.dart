import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

enum PaymentMethod { upi, netbanking, debitCard, creditCard, phonePe, paytm }

enum PaymentStatus { pending, processing, completed, failed, cancelled }

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final uuid = Uuid();

  // Process payment based on the selected method
  Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    required String userId,
  }) async {
    try {
      // Create a payment ID
      final paymentId = uuid.v4();

      // Create a payment record in Firestore
      await _firestore.collection('payments').doc(paymentId).set({
        'id': paymentId,
        'bookingId': bookingId,
        'userId': userId,
        'amount': amount,
        'method': method.toString().split('.').last,
        'status': PaymentStatus.pending.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // In a real app, this would redirect to payment gateway
      // For this demo, we'll simulate a successful payment
      await Future.delayed(const Duration(seconds: 3));

      // Update payment status to completed
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.completed.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'paymentId': paymentId,
        'message': 'Payment successful',
      };
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return {'success': false, 'message': 'Payment failed: ${e.toString()}'};
    }
  }

  // Get payment status for a booking
  Future<PaymentStatus> getPaymentStatus(String bookingId) async {
    try {
      final snapshot =
          await _firestore
              .collection('payments')
              .where('bookingId', isEqualTo: bookingId)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return PaymentStatus.pending;
      }

      final data = snapshot.docs.first.data();
      final statusStr = data['status'] as String;

      switch (statusStr) {
        case 'pending':
          return PaymentStatus.pending;
        case 'processing':
          return PaymentStatus.processing;
        case 'completed':
          return PaymentStatus.completed;
        case 'failed':
          return PaymentStatus.failed;
        case 'cancelled':
          return PaymentStatus.cancelled;
        default:
          return PaymentStatus.pending;
      }
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return PaymentStatus.pending;
    }
  }

  // Get a mapping of payment method to display name
  static Map<PaymentMethod, String> get paymentMethodNames => {
    PaymentMethod.upi: 'UPI',
    PaymentMethod.netbanking: 'Net Banking',
    PaymentMethod.debitCard: 'Debit Card',
    PaymentMethod.creditCard: 'Credit Card',
    PaymentMethod.phonePe: 'PhonePe',
    PaymentMethod.paytm: 'Paytm',
  };

  // Get a mapping of payment method to icon
  static Map<PaymentMethod, IconData> get paymentMethodIcons => {
    PaymentMethod.upi: Icons.account_balance_wallet,
    PaymentMethod.netbanking: Icons.account_balance,
    PaymentMethod.debitCard: Icons.credit_card,
    PaymentMethod.creditCard: Icons.credit_card,
    PaymentMethod.phonePe: Icons.payment,
    PaymentMethod.paytm: Icons.payment,
  };
}
