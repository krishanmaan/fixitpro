import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixitpro/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service class that handles user authentication and management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;

  // Initialize GoogleSignIn lazily to avoid initialization errors
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      signInOption: SignInOption.standard,
      scopes: ['email'],
    );
    return _googleSignIn!;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register with email and password
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create user document in Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          phone: phone,
          savedAddresses: [],
          isAdmin: false,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toJson());

        return newUser;
      } else {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'user-creation-failed',
          message: 'Could not create account',
        );
      }
    } catch (e) {
      if (e is FirebaseException) {
        throw e;
      }
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  /// Login with email and password
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        } else {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'User profile not found in database',
          );
        }
      } else {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'login-failed',
          message: 'Could not log in',
        );
      }
    } catch (e) {
      if (e is FirebaseException) {
        rethrow;
      }
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'sign-in-cancelled',
          message: 'Google sign in was cancelled',
        );
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // User exists, return user model
          return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        } else {
          // Create new user in Firestore
          UserModel newUser = UserModel(
            id: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            photoUrl: user.photoURL,
            savedAddresses: [],
            isAdmin: false,
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toJson());

          return newUser;
        }
      } else {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'sign-in-failed',
          message: 'Google sign in failed',
        );
      }
    } catch (e) {
      // Handle debug-mode specific error fallback
      if (kDebugMode && e.toString().contains('com.google.android.gms')) {
        debugPrint('Using mock user for Google Sign-In in debug mode');
        String mockUserId = 'google_mock_user_123';

        // Create mock user model
        UserModel mockUser = UserModel(
          id: mockUserId,
          name: 'Demo User',
          email: 'demo@example.com',
          phone: '1234567890',
          photoUrl: 'https://ui-avatars.com/api/?name=Demo+User',
          savedAddresses: [],
          isAdmin: false,
        );

        return mockUser;
      }

      if (e is FirebaseException) {
        throw e;
      }

      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'google-sign-in-failed',
        message: e.toString(),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (e is FirebaseException) {
        rethrow;
      }
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'reset-failed',
        message: e.toString(),
      );
    }
  }

  /// Get user data from Firestore
  Future<UserModel> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      } else {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'User profile not found',
        );
      }
    } catch (e) {
      if (e is FirebaseException) {
        rethrow;
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  /// Update user data in Firestore
  Future<UserModel> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      return user;
    } catch (e) {
      if (e is FirebaseException) {
        rethrow;
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'update-failed',
        message: e.toString(),
      );
    }
  }

  /// Add saved address to user profile
  Future<UserModel> addSavedAddress(String userId, SavedAddress address) async {
    try {
      // Get current user data
      UserModel user = await getUserData(userId);

      // Add new address to list
      List<SavedAddress> updatedAddresses = [...user.savedAddresses, address];

      // Update user with new addresses
      UserModel updatedUser = user.copyWith(savedAddresses: updatedAddresses);

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updatedUser.toJson());

      return updatedUser;
    } catch (e) {
      if (e is FirebaseException) {
        rethrow;
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'address-add-failed',
        message: e.toString(),
      );
    }
  }

  /// Delete saved address from user profile
  Future<UserModel> deleteSavedAddress(String userId, String addressId) async {
    try {
      // Get current user data
      UserModel user = await getUserData(userId);

      // Remove address from list
      List<SavedAddress> updatedAddresses =
          user.savedAddresses
              .where((address) => address.id != addressId)
              .toList();

      // Update user with new addresses
      UserModel updatedUser = user.copyWith(savedAddresses: updatedAddresses);

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updatedUser.toJson());

      return updatedUser;
    } catch (e) {
      if (e is FirebaseException) {
        rethrow;
      }
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'address-delete-failed',
        message: e.toString(),
      );
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['isAdmin'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
