import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_theme.dart';
import 'package:fixitpro/firebase_options.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/providers/service_provider.dart';
import 'package:fixitpro/providers/booking_provider.dart';
import 'package:fixitpro/providers/admin_provider.dart';
import 'package:fixitpro/screens/auth/login_screen.dart';
import 'package:fixitpro/screens/auth/register_screen.dart';
import 'package:fixitpro/screens/auth/forgot_password_screen.dart';
import 'package:fixitpro/screens/booking/add_review_screen.dart';
import 'package:fixitpro/screens/booking/booking_detail_screen.dart';
import 'package:fixitpro/screens/booking/booking_history_screen.dart';
import 'package:fixitpro/screens/booking/booking_screen.dart';
import 'package:fixitpro/screens/booking/booking_success_screen.dart';
import 'package:fixitpro/screens/booking/payment_screen.dart';
import 'package:fixitpro/screens/booking/reschedule_screen.dart';
import 'package:fixitpro/screens/home/home_screen.dart';
import 'package:fixitpro/screens/home/service_detail_screen.dart';
import 'package:fixitpro/screens/home/services_by_category_screen.dart';
import 'package:fixitpro/screens/user/profile_screen.dart';
import 'package:fixitpro/screens/user/edit_profile_screen.dart';
import 'package:fixitpro/screens/user/address_screen.dart';
import 'package:fixitpro/screens/user/payment_methods_screen.dart';
import 'package:fixitpro/screens/user/notifications_screen.dart';
import 'package:fixitpro/screens/user/help_support_screen.dart';
import 'package:fixitpro/screens/splash_screen.dart';
import 'package:fixitpro/screens/admin/admin_dashboard_screen.dart';
import 'package:fixitpro/screens/admin/manage_services_screen.dart';
import 'package:fixitpro/screens/admin/manage_bookings_screen.dart';
import 'package:fixitpro/screens/admin/manage_support_requests_screen.dart';
import 'package:fixitpro/screens/admin/manage_time_slots_screen.dart';
import 'package:fixitpro/screens/admin/manage_users_screen.dart';
import 'package:fixitpro/screens/admin/view_reviews_screen.dart';
import 'package:fixitpro/screens/admin/admin_analytics_screen.dart';
import 'package:fixitpro/screens/admin/admin_notifications_panel.dart';
import 'package:fixitpro/screens/admin/manage_service_types_screen.dart';
import 'package:fixitpro/services/firebase_service.dart';

import 'package:fixitpro/models/booking_model.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and services
  bool firebaseInitialized = false;
  final FirebaseService firebaseService = FirebaseService();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize our Firebase service wrapper
    await firebaseService.initialize();

    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    firebaseInitialized = false;
  }

  // Run app with firebase initialization result
  runApp(
    MyApp(
      firebaseInitialized: firebaseInitialized,
      firebaseService: firebaseService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final IFirebaseService firebaseService;

  const MyApp({
    super.key,
    required this.firebaseInitialized,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the Firebase service
        Provider<IFirebaseService>.value(value: firebaseService),

        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Service provider depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, ServiceProvider>(
          create: (_) => ServiceProvider(),
          update: (_, authProvider, serviceProvider) {
            // Initialize services when auth changes
            if (authProvider.isAuthenticated &&
                serviceProvider != null &&
                !serviceProvider.hasLoaded) {
              serviceProvider.loadServices();
            }
            return serviceProvider ?? ServiceProvider();
          },
        ),

        // Booking provider depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, authProvider, bookingProvider) {
            // Load user bookings when auth changes to authenticated
            if (authProvider.isAuthenticated && bookingProvider != null) {
              bookingProvider.loadUserBookings();
            }
            return bookingProvider ?? BookingProvider();
          },
        ),

        // Admin provider depends on Auth
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, authProvider, adminProvider) {
            if (authProvider.isAuthenticated && adminProvider != null) {
              // Check admin status when auth changes
              adminProvider.checkAdminStatus();
            }
            return adminProvider ?? AdminProvider();
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'FixItPro',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // Add global wrapper for better layout
              return MediaQuery(
                // Adjust padding to avoid overflow issues
                data: MediaQuery.of(context).copyWith(
                  padding: MediaQuery.of(context).padding.copyWith(top: 0),
                ),
                child: Column(
                  children: [
                    if (!firebaseInitialized)
                      Material(
                        color: Colors.amber.shade100,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Warning: Offline mode - some features may be limited",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Material(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [if (child != null) child],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            home: const SplashScreen(),
            routes: {
              // Auth
              LoginScreen.routeName: (context) => const LoginScreen(),
              RegisterScreen.routeName: (context) => const RegisterScreen(),
              ForgotPasswordScreen.routeName:
                  (context) => const ForgotPasswordScreen(),

              // Home
              HomeScreen.routeName: (context) => const HomeScreen(),
              ServiceDetailScreen.routeName:
                  (context) => const ServiceDetailScreen(),
              ServicesByCategoryScreen.routeName:
                  (context) => const ServicesByCategoryScreen(
                    categoryId: 'all',
                    categoryName: 'All Services',
                  ),

              // User
              ProfileScreen.routeName: (context) => const ProfileScreen(),
              EditProfileScreen.routeName:
                  (context) => const EditProfileScreen(),
              AddressScreen.routeName: (context) => const AddressScreen(),
              PaymentMethodsScreen.routeName:
                  (context) => const PaymentMethodsScreen(),
              NotificationsScreen.routeName:
                  (context) => const NotificationsScreen(),
              HelpSupportScreen.routeName:
                  (context) => const HelpSupportScreen(),

              // Booking
              BookingScreen.routeName: (context) => const BookingScreen(),
              PaymentScreen.routeName: (context) {
                // Extract the arguments to pass to PaymentScreen
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                if (args != null) {
                  return PaymentScreen(
                    pendingBooking: args['pendingBooking'],
                    amount: args['amount'],
                  );
                }
                // Fallback if no arguments are provided
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Please select a service to proceed to payment',
                    ),
                  ),
                );
              },
              BookingSuccessScreen.routeName: (context) {
                // Extract the arguments as BookingModel
                final booking =
                    ModalRoute.of(context)?.settings.arguments as BookingModel?;
                if (booking != null) {
                  return BookingSuccessScreen(booking: booking);
                }
                // Fallback if no arguments are provided
                return const Scaffold(
                  body: Center(
                    child: Text(
                      'Please book a service to see the success screen',
                    ),
                  ),
                );
              },
              BookingHistoryScreen.routeName:
                  (context) => const BookingHistoryScreen(),
              BookingDetailScreen.routeName:
                  (context) => const BookingDetailScreen(),
              AddReviewScreen.routeName: (context) => const AddReviewScreen(),
              RescheduleScreen.routeName: (context) => const RescheduleScreen(),

              // Admin
              AdminDashboardScreen.routeName:
                  (context) => const AdminDashboardScreen(),
              ManageServicesScreen.routeName:
                  (context) => const ManageServicesScreen(),
              ManageServiceTypesScreen.routeName:
                  (context) => const ManageServiceTypesScreen(),
              ManageBookingsScreen.routeName:
                  (context) => const ManageBookingsScreen(),
              ManageTimeSlotsScreen.routeName:
                  (context) => const ManageTimeSlotsScreen(),
              ManageUsersScreen.routeName:
                  (context) => const ManageUsersScreen(),
              ViewReviewsScreen.routeName:
                  (context) => const ViewReviewsScreen(),
              AdminAnalyticsScreen.routeName:
                  (context) => const AdminAnalyticsScreen(),
              AdminNotificationsPanel.routeName:
                  (context) => const AdminNotificationsPanel(),
              ManageSupportRequestsScreen.routeName:
                  (context) => const ManageSupportRequestsScreen(),
            },
          );
        },
      ),
    );
  }
}

// Wrapper to decide which screen to show based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.status) {
      case AuthStatus.authenticated:
        // Check if user is admin and navigate accordingly
        if (authProvider.isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const HomeScreen();
        }
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      default:
        // For uninitialized state, show a loading screen
        return const SplashScreen();
    }
  }
}
