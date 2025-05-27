import 'package:flutter/material.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:intl/intl.dart';

class ViewReviewsScreen extends StatefulWidget {
  static const String routeName = '/admin/view-reviews';

  const ViewReviewsScreen({super.key});

  @override
  State<ViewReviewsScreen> createState() => _ViewReviewsScreenState();
}

class _ViewReviewsScreenState extends State<ViewReviewsScreen> {
  final bool _isLoading = false;
  int _selectedRating = 0; // 0 means all ratings
  String _selectedService = 'All Services';

  @override
  Widget build(BuildContext context) {
    // Placeholder for reviews data
    // In a real implementation, this would come from a provider
    final List<Map<String, dynamic>> reviews = [
      {
        'id': '1',
        'userName': 'John Doe',
        'userImage': null,
        'rating': 5,
        'comment':
            'Excellent service! The technician was very professional and completed the job quickly. Would definitely recommend.',
        'serviceName': 'AC Repair',
        'date': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '2',
        'userName': 'Alice Smith',
        'userImage': null,
        'rating': 4,
        'comment':
            'Good job overall. The work was done well, but there was a slight delay in arrival time.',
        'serviceName': 'Plumbing Service',
        'date': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'id': '3',
        'userName': 'Robert Johnson',
        'userImage': null,
        'rating': 3,
        'comment':
            'Average experience. The service was okay but could have been better.',
        'serviceName': 'Electrical Repair',
        'date': DateTime.now().subtract(const Duration(days: 10)),
      },
      {
        'id': '4',
        'userName': 'Emily Wilson',
        'userImage': null,
        'rating': 5,
        'comment':
            'Amazing work! The technician was knowledgeable and fixed my issue efficiently.',
        'serviceName': 'AC Repair',
        'date': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': '5',
        'userName': 'David Brown',
        'userImage': null,
        'rating': 2,
        'comment':
            'Disappointing experience. The work took longer than expected and there were issues after completion.',
        'serviceName': 'Plumbing Service',
        'date': DateTime.now().subtract(const Duration(days: 20)),
      },
    ];

    // Filter reviews based on selected filters
    final filteredReviews =
        reviews.where((review) {
          if (_selectedRating > 0 && review['rating'] != _selectedRating) {
            return false;
          }

          if (_selectedService != 'All Services' &&
              review['serviceName'] != _selectedService) {
            return false;
          }

          return true;
        }).toList();

    // Get unique service names for the filter
    final services = [
      'All Services',
      ...reviews.map((review) => review['serviceName'] as String).toSet(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Reviews')),
      body: Column(
        children: [
          _buildFilters(services),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredReviews.isEmpty
                    ? const Center(
                      child: Text(
                        'No reviews match your filters',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredReviews.length,
                      itemBuilder: (context, index) {
                        final review = filteredReviews[index];
                        return _buildReviewCard(review);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<String> services) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25), // 0.1 opacity (255 * 0.1)
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'By Rating',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRatingFilter(0, 'All'),
                          _buildRatingFilter(5, '5'),
                          _buildRatingFilter(4, '4'),
                          _buildRatingFilter(3, '3'),
                          _buildRatingFilter(2, '2'),
                          _buildRatingFilter(1, '1'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'By Service',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedService,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      items:
                          services.map((service) {
                            return DropdownMenuItem(
                              value: service,
                              child: Text(service),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedService = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter(int rating, String label) {
    final isSelected = _selectedRating == rating;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = rating;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            if (rating > 0) ...[
              Icon(
                Icons.star,
                size: 16,
                color: isSelected ? Colors.white : Colors.amber,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final dateFormat = DateFormat('MMM dd, yyyy');

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
                CircleAvatar(
                  backgroundColor: AppConstants.primaryColor.withAlpha(
                    51,
                  ), // 0.2 opacity (255 * 0.2)
                  child:
                      review['userImage'] != null
                          ? ClipOval(
                            child: Image.network(
                              review['userImage'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.person,
                                    color: AppConstants.primaryColor,
                                  ),
                            ),
                          )
                          : const Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dateFormat.format(review['date']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRatingStars(review['rating']),
              ],
            ),
            const SizedBox(height: 12),
            Text(review['comment'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                review['serviceName'],
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _respondToReview(review),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Respond'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  void _respondToReview(Map<String, dynamic> review) {
    final TextEditingController responseController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Respond to Review'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Responding to ${review['userName']}\'s review:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  review['comment'],
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    hintText: 'Type your response...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (responseController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a response'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();

                  // In a real app, you would send this response to the database
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Response submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }
}
