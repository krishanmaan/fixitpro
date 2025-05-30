import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:fixitpro/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _forceAdminAccess = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _forceAdminAccess || (_user?.isAdmin ?? false);
  bool get isInitialized => _isInitialized;

  // Constructor
  AuthProvider() {
    _initAuth();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Force admin access for development purposes
  void setForceAdminAccess(bool value) {
    _forceAdminAccess = value;
    notifyListeners();
  }

  // Initialize authentication
  Future<void> _initAuth() async {
    _status = AuthStatus.uninitialized;
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen((
        firebase_auth.User? firebaseUser,
      ) async {
        if (firebaseUser == null) {
          _status = AuthStatus.unauthenticated;
          _user = null;
          _isInitialized = true;
          _isLoading = false;
          notifyListeners();
        } else {
          try {
            // Get user data from Realtime Database
            final snapshot = await _database.ref('users/${firebaseUser.uid}').get();

            if (snapshot.exists) {
              final userData = snapshot.value as Map<dynamic, dynamic>;
              _user = UserModel.fromJson({
                ...Map<String, dynamic>.from(userData),
                'id': firebaseUser.uid,
              });
              _status = AuthStatus.authenticated;
            } else {
              // For development - create a mock user if database access fails
              debugPrint('Creating mock user for development during initialization');
              _user = UserModel(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'User',
                email: firebaseUser.email ?? 'user@example.com',
                phone: firebaseUser.phoneNumber ?? '1234567890',
                savedAddresses: _createMockAddresses(),
                isAdmin: false,
              );
              _status = AuthStatus.authenticated;
            }
          } catch (e) {
            debugPrint('Error getting user data: $e');

            // For development - create a mock user if database access fails
            if (e.toString().contains('permission-denied') ||
                e.toString().contains('not-found')) {
              debugPrint('Creating mock user for development during initialization');
              _user = UserModel(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'User',
                email: firebaseUser.email ?? 'user@example.com',
                phone: firebaseUser.phoneNumber ?? '1234567890',
                savedAddresses: _createMockAddresses(),
                isAdmin: false,
              );
              _status = AuthStatus.authenticated;
            } else {
              _status = AuthStatus.unauthenticated;
              _user = null;
            }
          } finally {
            _isInitialized = true;
            _isLoading = false;
            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _status = AuthStatus.unauthenticated;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with email and password
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _error = null;
      notifyListeners();

      // Create user with email and password
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'null-user',
          message: 'Failed to create user account',
        );
      }

      // Check if this is the first user (make them an admin)
      final adminSnapshot = await _database.ref('admins').get();
      final isFirstUser = !adminSnapshot.exists;

      // Create user model
      final newUser = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        savedAddresses: [],
        isAdmin: isFirstUser, // First user becomes an admin
      );

      try {
        // Create user document in Realtime Database
        await _database.ref('users/${newUser.id}').set(newUser.toJson());
        
        // If this is the first user, add them to admins
        if (isFirstUser) {
          await _database.ref('admins/${newUser.id}').set({
            'email': email,
            'name': name,
            'createdAt': ServerValue.timestamp,
          });
        }
      } catch (dbError) {
        debugPrint('Database error: $dbError');
        // If database operation fails, delete the auth user
        await userCredential.user?.delete();
        throw firebase_auth.FirebaseAuthException(
          code: 'permission-denied',
          message: 'Failed to create user profile. Please check database permissions.',
        );
      }

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      // Set the user and update status
      _user = newUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      debugPrint('Registration error: $e');
      _status = AuthStatus.unauthenticated;
      if (e is firebase_auth.FirebaseAuthException) {
        _error = e.message ?? 'An error occurred during registration';
      } else {
        _error = e.toString();
      }
      notifyListeners();
      rethrow;
    }
  }

  // Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;

    try {
      debugPrint('Attempting login for email: $email');
      
      // Sign in with Firebase Auth
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        debugPrint('Login failed: No user returned');
        throw 'Failed to sign in';
      }

      debugPrint('Firebase Auth successful, getting user data...');
      
      // Get user data from Realtime Database
      final snapshot = await _database.ref('users/${userCredential.user!.uid}').get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        debugPrint('User data found: ${userData.toString()}');
        debugPrint('isAdmin status: ${userData['isAdmin']}');
        
        _user = UserModel.fromJson({
          ...Map<String, dynamic>.from(userData),
          'id': userCredential.user!.uid,
        });

        // Double check admin status in admins collection
        if (_user?.isAdmin == true) {
          debugPrint('User marked as admin, verifying admin status...');
          final adminSnapshot = await _database.ref('admins/${userCredential.user!.uid}').get();
          if (!adminSnapshot.exists) {
            debugPrint('Warning: User marked as admin but no admin document found');
            // Create admin document
            await _database.ref('admins/${userCredential.user!.uid}').set({
              'email': email,
              'name': _user?.name ?? '',
              'createdAt': ServerValue.timestamp,
            });
            debugPrint('Created admin document');
          } else {
            debugPrint('Admin document verified');
          }
        }

        _status = AuthStatus.authenticated;

        // Save login state
        _saveLoginState();

        debugPrint('Login successful, isAdmin: ${_user?.isAdmin}');
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        debugPrint('No user data found in database');
        throw firebase_auth.FirebaseAuthException(
          code: 'not-found',
          message: 'User profile not found in database',
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _error = _getReadableErrorMessage(e.toString());
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Helper method to create mock addresses for development
  List<SavedAddress> _createMockAddresses() {
    return [
      SavedAddress(
        id: 'address-1',
        label: 'Home',
        address: '123 Main St, New York, NY 10001',
        latitude: 40.7128,
        longitude: -74.0060,
      ),
      SavedAddress(
        id: 'address-2',
        label: 'Work',
        address: '456 Park Ave, New York, NY 10022',
        latitude: 40.7589,
        longitude: -73.9851,
      ),
    ];
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.signInWithGoogle();

      _status = AuthStatus.authenticated;

      // Save login state
      _saveLoginState();

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');

      // For development - create a mock user when Firebase access fails
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('not-found')) {
        debugPrint('Creating mock user for Google Sign-In development');
        _user = UserModel(
          id: 'mock-google-user-id',
          name: 'Google User',
          email: 'google.user@example.com',
          phone: '1234567890',
          savedAddresses: _createMockAddresses(),
          isAdmin: false,
        );
        _status = AuthStatus.authenticated;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _error = _getReadableErrorMessage(e.toString());
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      // Clear saved login state
      _clearLoginState();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      _error = _getReadableErrorMessage(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      _error = _getReadableErrorMessage(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _error = null;

    try {
      final updatedUser = _user!.copyWith(name: name, phone: phone);

      _user = await _authService.updateUserData(updatedUser);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      _error = _getReadableErrorMessage(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Add a saved address
  Future<bool> addAddress(SavedAddress address) async {
    if (_user == null) return false;

    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.addSavedAddress(_user!.id, address);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add address error: $e');
      _error = _getReadableErrorMessage(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete a saved address
  Future<bool> deleteAddress(String addressId) async {
    if (_user == null) return false;

    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.deleteSavedAddress(_user!.id, addressId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete address error: $e');
      _error = _getReadableErrorMessage(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Alias for addAddress - for backward compatibility
  Future<bool> addSavedAddress(SavedAddress address) async {
    return addAddress(address);
  }

  // Alias for deleteAddress - for backward compatibility
  Future<bool> deleteSavedAddress(String addressId) async {
    return deleteAddress(addressId);
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_user == null || _status != AuthStatus.authenticated) return;

    try {
      _user = await _authService.getUserData(_user!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  // Save login state to preferences
  Future<void> _saveLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      if (_user != null) {
        await prefs.setString('userData', _user!.toJson().toString());
      }
    } catch (e) {
      debugPrint('Error saving login state: $e');
    }
  }

  // Clear login state from preferences
  Future<void> _clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      debugPrint('Error clearing login state: $e');
    }
  }

  // Convert Firebase errors to readable messages
  String _getReadableErrorMessage(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Your password is too weak. Please choose a stronger password.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorMessage.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'This operation is not allowed. Please contact support.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again.';
    } else if (errorMessage.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
