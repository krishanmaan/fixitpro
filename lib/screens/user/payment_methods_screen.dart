import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/widgets/custom_appbar.dart';

class PaymentMethodsScreen extends StatefulWidget {
  static const String routeName = '/payment-methods';

  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = true;
  List<PaymentMethod> _paymentMethods = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('paymentMethods')
              .get();

      if (!mounted) return;

      setState(() {
        _paymentMethods =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return PaymentMethod(
                id: doc.id,
                cardNumber: data['cardNumber'] as String,
                cardHolderName: data['cardHolderName'] as String,
                expiryDate: data['expiryDate'] as String,
                isDefault: data['isDefault'] as bool? ?? false,
                cardType: data['cardType'] as String? ?? 'visa',
              );
            }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payment methods: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePaymentMethod(PaymentMethod method) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // If this is set as default, update all other methods to non-default
      if (method.isDefault) {
        final batch = _firestore.batch();
        final snapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('paymentMethods')
                .get();

        for (var doc in snapshot.docs) {
          if (doc.id != method.id) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }

        await batch.commit();
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('paymentMethods')
          .doc(method.id)
          .set({
            'cardNumber': method.cardNumber,
            'cardHolderName': method.cardHolderName,
            'expiryDate': method.expiryDate,
            'isDefault': method.isDefault,
            'cardType': method.cardType,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _loadPaymentMethods();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving payment method: $e')),
      );
    }
  }

  Future<void> _deletePaymentMethod(String id) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('paymentMethods')
          .doc(id)
          .delete();

      if (!mounted) return;

      setState(() {
        _paymentMethods.removeWhere((method) => method.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting payment method: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _paymentMethods.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off,
                      size: 70,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No payment methods saved yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditPaymentDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Payment Method'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return _buildPaymentMethodCard(method);
                },
              ),
      floatingActionButton:
          _paymentMethods.isNotEmpty
              ? FloatingActionButton(
                onPressed: () => _showAddEditPaymentDialog(context),
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getCardIcon(method.cardType),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    method.cardHolderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (method.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '•••• •••• •••• ${method.cardNumber.substring(method.cardNumber.length - 4)}',
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text(
              'Expires: ${method.expiryDate}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed:
                      () => _showAddEditPaymentDialog(context, method: method),
                  icon: Icon(
                    Icons.edit,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    'Edit',
                    style: TextStyle(color: AppConstants.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(context, method),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCardIcon(String cardType) {
    IconData iconData;
    Color color;

    switch (cardType.toLowerCase()) {
      case 'visa':
        iconData = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        iconData = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'amex':
        iconData = Icons.credit_card;
        color = Colors.blueGrey;
        break;
      default:
        iconData = Icons.credit_card;
        color = Colors.grey;
        break;
    }

    return Icon(iconData, color: color);
  }

  void _showAddEditPaymentDialog(
    BuildContext context, {
    PaymentMethod? method,
  }) {
    final isEditing = method != null;
    final cardNumberController = TextEditingController(
      text: isEditing ? method.cardNumber : '',
    );
    final cardHolderController = TextEditingController(
      text: isEditing ? method.cardHolderName : '',
    );
    final expiryDateController = TextEditingController(
      text: isEditing ? method.expiryDate : '',
    );
    bool isDefault = isEditing ? method.isDefault : false;
    String cardType = isEditing ? method.cardType : 'visa';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    isEditing ? 'Edit Payment Method' : 'Add Payment Method',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Number
                        TextField(
                          controller: cardNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            hintText: 'XXXX XXXX XXXX XXXX',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                        ),
                        const SizedBox(height: 8),

                        // Card Holder Name
                        TextField(
                          controller: cardHolderController,
                          decoration: const InputDecoration(
                            labelText: 'Card Holder Name',
                            hintText: 'John Doe',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),

                        // Expiry Date
                        TextField(
                          controller: expiryDateController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            hintText: 'MM/YY',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                        ),
                        const SizedBox(height: 8),

                        // Card Type
                        DropdownButtonFormField<String>(
                          value: cardType,
                          decoration: const InputDecoration(
                            labelText: 'Card Type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'visa',
                              child: Text('Visa'),
                            ),
                            DropdownMenuItem(
                              value: 'mastercard',
                              child: Text('MasterCard'),
                            ),
                            DropdownMenuItem(
                              value: 'amex',
                              child: Text('American Express'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                cardType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Set as Default
                        Row(
                          children: [
                            Checkbox(
                              value: isDefault,
                              onChanged: (value) {
                                setState(() {
                                  isDefault = value ?? false;
                                });
                              },
                            ),
                            const Text('Set as default payment method'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Validate input
                        if (cardNumberController.text.isEmpty ||
                            cardHolderController.text.isEmpty ||
                            expiryDateController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                            ),
                          );
                          return;
                        }

                        // Validate expiry date format
                        if (!RegExp(
                          r'^\d{2}/\d{2}$',
                        ).hasMatch(expiryDateController.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Expiry date must be in MM/YY format',
                              ),
                            ),
                          );
                          return;
                        }

                        final paymentMethod = PaymentMethod(
                          id: isEditing ? method.id : DateTime.now().toString(),
                          cardNumber: cardNumberController.text,
                          cardHolderName: cardHolderController.text,
                          expiryDate: expiryDateController.text,
                          isDefault: isDefault,
                          cardType: cardType,
                        );

                        Navigator.pop(context);
                        _savePaymentMethod(paymentMethod);
                      },
                      child: Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod method) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Payment Method'),
            content: Text(
              'Are you sure you want to delete this payment method? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePaymentMethod(method.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final bool isDefault;
  final String cardType;

  PaymentMethod({
    required this.id,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    this.isDefault = false,
    this.cardType = 'visa',
  });
}
