import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/providers/auth_provider.dart';

class HelpSupportScreen extends StatefulWidget {
  static const String routeName = '/help-support';

  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late TabController _tabController;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppConstants.primaryColor,
                    width: 3.0,
                  ),
                ),
              ),
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [Tab(text: 'FAQs'), Tab(text: 'Contact Us')],
            ),
          ),

          // Tab content
          Expanded(
            child: _selectedTab == 0 ? _buildFAQs() : _buildContactForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQs() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFAQCategory('Booking & Services', [
          {
            'question': 'How do I book a service?',
            'answer':
                'You can book a service by browsing through available services in the app, selecting the one you need, choosing your preferred date and time, and completing the booking process.',
          },
          {
            'question': 'Can I reschedule my booking?',
            'answer':
                'Yes, you can reschedule your booking up to 4 hours before the scheduled service time. Go to My Bookings, select the booking you want to reschedule, and tap on the Reschedule button.',
          },
          {
            'question': 'How do I cancel a booking?',
            'answer':
                'To cancel a booking, go to My Bookings, select the booking you want to cancel, and tap on the Cancel button. Please note that cancellations made less than 24 hours before the scheduled service time may incur a cancellation fee.',
          },
          {
            'question': 'What if I\'m not satisfied with the service?',
            'answer':
                'Your satisfaction is our priority. If you\'re not satisfied with the service, please contact our customer support within 48 hours of service completion, and we\'ll address your concerns promptly.',
          },
        ]),

        _buildFAQCategory('Payments & Billing', [
          {
            'question': 'What payment methods are accepted?',
            'answer':
                'We accept various payment methods including credit/debit cards, digital wallets, and cash on delivery for certain services.',
          },
          {
            'question': 'How do I get an invoice for my booking?',
            'answer':
                'An invoice is automatically generated after the service is completed and payment is made. You can find it in the My Bookings section under the specific booking details.',
          },
          {
            'question': 'Are there any hidden charges?',
            'answer':
                'No, there are no hidden charges. The price shown during the booking process is inclusive of all charges, except for any additional services or parts that may be required during the service, which will be communicated to you before proceeding.',
          },
        ]),

        _buildFAQCategory('Account & Profile', [
          {
            'question': 'How do I update my profile information?',
            'answer':
                'You can update your profile information by going to the Profile section and tapping on Edit Profile. Here you can update your name, phone number, and profile picture.',
          },
          {
            'question': 'How do I add or remove an address?',
            'answer':
                'To add or remove an address, go to Profile, tap on My Addresses, and then use the Add New Address button or the delete option next to existing addresses.',
          },
          {
            'question': 'How do I reset my password?',
            'answer':
                'To reset your password, go to the Login screen, tap on Forgot Password, enter your email address, and follow the instructions sent to your email.',
          },
        ]),
      ],
    );
  }

  Widget _buildFAQCategory(String title, List<Map<String, String>> faqs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
        ...faqs.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Text(
          answer,
          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildContactForm() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Support',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fill out the form below, and our team will get back to you within 24 hours.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // User info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Name:'),
                    const SizedBox(width: 8),
                    Text(
                      user?.name ?? 'Not logged in',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Email:'),
                    const SizedBox(width: 8),
                    Text(
                      user?.email ?? 'Not logged in',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subject
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isSubmitting ? null : () => _submitSupportRequest(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 32),

          // Alternative contact methods
          const Text(
            'Other Ways to Reach Us',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, String>>(
            future: _getContactInfo(),
            builder: (context, snapshot) {
              final contactInfo =
                  snapshot.data ??
                  {
                    'phone': '+1 800 FIX-ITPRO',
                    'email': 'support@fixitpro.com',
                  };

              return Column(
                children: [
                  _buildContactMethod(
                    Icons.phone,
                    'Phone',
                    contactInfo['phone']!,
                    () => _launchUrl(
                      'tel:${contactInfo['phone']!.replaceAll(RegExp(r'[^\d+]'), '')}',
                    ),
                  ),
                  _buildContactMethod(
                    Icons.email,
                    'Email',
                    contactInfo['email']!,
                    () => _launchUrl('mailto:${contactInfo['email']}'),
                  ),
                  _buildContactMethod(
                    Icons.chat,
                    'Live Chat',
                    'Available 9 AM - 6 PM',
                    () => _startLiveChat(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppConstants.primaryColor),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>> _getContactInfo() async {
    try {
      final docSnapshot =
          await _firestore.collection('app_settings').doc('contact_info').get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return {
          'phone': data['phone'] ?? '+1 800 FIX-ITPRO',
          'email': data['email'] ?? 'support@fixitpro.com',
        };
      }
    } catch (e) {
      debugPrint('Error loading contact info: $e');
    }

    // Return default values if not found
    return {'phone': '+1 800 FIX-ITPRO', 'email': 'support@fixitpro.com'};
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _startLiveChat() {
    // Placeholder for live chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live chat feature coming soon!')),
    );
  }

  Future<void> _submitSupportRequest(dynamic user) async {
    // Validate inputs
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a subject')));
      return;
    }

    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = _auth.currentUser?.uid;

      // Create support request document
      await _firestore.collection('support_requests').add({
        'userId': userId,
        'name': user?.name ?? 'Guest',
        'email': user?.email ?? 'No email provided',
        'subject': _subjectController.text,
        'message': _messageController.text,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      _subjectController.clear();
      _messageController.clear();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your support request has been submitted. We\'ll get back to you soon.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
