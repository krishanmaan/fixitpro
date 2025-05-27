import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/screens/auth/login_screen.dart';
import 'package:fixitpro/screens/home/home_screen.dart';
import 'package:fixitpro/screens/admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Start checking auth state immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });

    // Set a fallback timer to ensure navigation happens
    Timer(const Duration(seconds: 2), () {
      if (!_isNavigating) {
        _navigate();
      }
    });
  }

  void _checkAuthState() {
    if (_isNavigating) return; // Prevent multiple navigations

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize the auth provider if needed
    if (authProvider.status == AuthStatus.uninitialized) {
      // Check again after a short delay
      Timer(const Duration(milliseconds: 500), () {
        _checkAuthState();
      });
      return;
    }

    // Auth state is determined, navigate
    _navigate();
  }

  void _navigate() {
    if (_isNavigating) return; // Prevent multiple navigations
    _isNavigating = true;

    setState(() {
      _isLoading = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Allow the animation to finish
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        if (authProvider.status == AuthStatus.authenticated) {
          // Check if user is admin and navigate accordingly
          if (authProvider.isAdmin) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AdminDashboardScreen.routeName);
          } else {
            Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
          }
        } else {
          Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppConstants.backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: size.width * 0.35,
                    height: size.width * 0.35,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(size.width * 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withAlpha(100),
                          spreadRadius: 2,
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.handyman,
                      color: AppConstants.whiteColor,
                      size: size.width * 0.18,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Text animations
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: size.width * 0.08,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Book, Repair & Relax',
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: AppConstants.lightTextColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Loading indicator
                if (_isLoading)
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryColor,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
