import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixitpro/constants/app_constants.dart';
import 'package:fixitpro/providers/auth_provider.dart';
import 'package:fixitpro/screens/auth/register_screen.dart';
import 'package:fixitpro/screens/auth/forgot_password_screen.dart';
import 'package:fixitpro/widgets/custom_button.dart';
import 'package:fixitpro/widgets/custom_text_field.dart';
import 'package:fixitpro/screens/home/home_screen.dart';
import 'package:fixitpro/screens/admin/admin_dashboard_screen.dart';

// Helper function to safely create non-const BorderRadius
BorderRadius getDefaultBorderRadius() {
  return BorderRadius.circular(AppConstants.defaultBorderRadius);
}

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-compute the BorderRadius outside of the build method
    // to avoid constant value issues
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value);
    if (!emailValid) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (success && mounted) {
          // Navigate based on user role
          if (authProvider.isAdmin) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AdminDashboardScreen.routeName);
          } else {
            Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
          }
        } else if (!success && mounted) {
          setState(() {
            _errorMessage = authProvider.error;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        // Navigate based on user role
        if (authProvider.isAdmin) {
          Navigator.of(
            context,
          ).pushReplacementNamed(AdminDashboardScreen.routeName);
        } else {
          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        }
      } else if (!success && mounted) {
        setState(() {
          _errorMessage = authProvider.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, RegisterScreen.routeName);
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, ForgotPasswordScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If auth state changes and user is authenticated, navigate to the appropriate screen
    if (authProvider.isAuthenticated && _isLoading) {
      // Instead of immediately changing state during build, schedule it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (authProvider.isAdmin) {
            Navigator.of(
              context,
            ).pushReplacementNamed(AdminDashboardScreen.routeName);
          } else {
            Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48.0),
                    child: Column(
                      children: [
                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Book, Repair & Relax',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppConstants.lightTextColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Welcome Back Text
                  Text(
                    'Welcome Back!',
                    style: AppConstants.getResponsiveHeadingStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: AppConstants.getResponsiveSmallTextStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: AppConstants.errorColor.withAlpha(26),
                        borderRadius: getDefaultBorderRadius(),
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
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  PasswordTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    validator: _validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signInWithEmailAndPassword(),
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _navigateToForgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _signInWithEmailAndPassword,
                    isLoading: _isLoading && authProvider.error == null,
                  ),
                  const SizedBox(height: 24),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: AppConstants.dividerColor,
                          thickness: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppConstants.lightTextColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: AppConstants.dividerColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google Sign In Button
                  CustomButton(
                    text: 'Continue with Google',
                    onPressed: _signInWithGoogle,
                    isPrimary: false,
                    icon: Icons.g_mobiledata,
                    isLoading: _isLoading && authProvider.error != null,
                  ),
                  const SizedBox(height: 32),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppConstants.lightTextColor,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
