import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/models/booking_model.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/widgets/custom_button.dart';
import 'package:fixitpro/widgets/custom_text_field.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AddReviewScreen extends StatefulWidget {
  static const String routeName = '/add-review';

  final String bookingId;

  const AddReviewScreen({super.key, required this.bookingId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _rating = 4.0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(BookingModel booking) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final bookingProvider = Provider.of<BookingProvider>(
          context,
          listen: false,
        );

        if (authProvider.user == null) {
          throw Exception('Please login to submit a review');
        }

        await bookingProvider.addReview(
          bookingId: widget.bookingId,
          rating: _rating,
          comment: _commentController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Review'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Info
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image:
                              booking.serviceImage.isNotEmpty
                                  ? NetworkImage(booking.serviceImage)
                                      as ImageProvider
                                  : const AssetImage(
                                    'assets/images/placeholder.png',
                                  ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: ${booking.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.lightTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppConstants.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppConstants.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rating
              const Text(
                'How would you rate the service?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder:
                      (context, _) => const Icon(
                        Icons.star,
                        color: AppConstants.accentColor,
                      ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingLabel(_rating),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getRatingColor(_rating),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Comment
              const Text(
                'Share your experience',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Your Review',
                hint: 'What did you like or dislike about the service?',
                controller: _commentController,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your review';
                  }
                  if (value.length < 10) {
                    return 'Review must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Submit Review',
                onPressed: () => _submitReview(booking),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 4.5) {
      return 'Excellent';
    } else if (rating >= 3.5) {
      return 'Very Good';
    } else if (rating >= 2.5) {
      return 'Good';
    } else if (rating >= 1.5) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) {
      return AppConstants.successColor;
    } else if (rating >= 3.5) {
      return AppConstants.accentColor;
    } else if (rating >= 2.5) {
      return Colors.amber;
    } else if (rating >= 1.5) {
      return Colors.orange;
    } else {
      return AppConstants.errorColor;
    }
  }
}
