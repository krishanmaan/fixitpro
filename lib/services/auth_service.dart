import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:fixitpro/models/user_model.dart';

/// Service class that handles user authentication and management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

        // Create user document in Realtime Database
        UserModel newUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          phone: phone,
          savedAddresses: [],
          isAdmin: false,
        );

        await _database
            .ref('users/${user.uid}')
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
        rethrow;
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
        // Get user data from Realtime Database
        final snapshot = await _database.ref('users/${user.uid}').get();

        if (snapshot.exists) {
          final userData = snapshot.value as Map<dynamic, dynamic>;
          return UserModel.fromJson(Map<String, dynamic>.from(userData));
        } else {
          throw FirebaseException(
            plugin: 'firebase_database',
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
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign in aborted';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw 'Failed to sign in with Google';
      }

      // Check if user exists in database
      final userDoc = await _database.ref('users/${userCredential.user!.uid}').get();

      if (!userDoc.exists) {
        // Create new user document if it doesn't exist
        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          savedAddresses: [],
          isAdmin: false,
        );

        await _database.ref('users/${newUser.id}').set(newUser.toJson());
        return newUser;
      }

      // Return existing user data
      final userData = userDoc.value as Map<dynamic, dynamic>;
      return UserModel.fromJson({
        ...Map<String, dynamic>.from(userData),
        'id': userCredential.user!.uid,
      });
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  /// Get user data from Realtime Database
  Future<UserModel?> getUserData(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _database.ref('users/${user.uid}').get();
      
      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Update user data in Realtime Database
  Future<UserModel> updateUserData(UserModel user) async {
    try {
      await _database.ref('users/${user.id}').update(user.toJson());
      return user;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  /// Add saved address to user profile
  Future<UserModel> addSavedAddress(String userId, SavedAddress address) async {
    try {
      final userDoc = await _database.ref('users/$userId').get();

      if (!userDoc.exists) {
        throw 'User not found';
      }

      final userData = userDoc.value as Map<dynamic, dynamic>;
      final user = UserModel.fromJson({
        ...Map<String, dynamic>.from(userData),
        'id': userId,
      });

      final updatedAddresses = [...user.savedAddresses, address];
      final updatedUser = user.copyWith(savedAddresses: updatedAddresses);

      await _database.ref('users/$userId').update({
        'savedAddresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
      });

      return updatedUser;
    } catch (e) {
      debugPrint('Error adding saved address: $e');
      rethrow;
    }
  }

  /// Delete saved address from user profile
  Future<UserModel> deleteSavedAddress(String userId, String addressId) async {
    try {
      final userDoc = await _database.ref('users/$userId').get();

      if (!userDoc.exists) {
        throw 'User not found';
      }

      final userData = userDoc.value as Map<dynamic, dynamic>;
      final user = UserModel.fromJson({
        ...Map<String, dynamic>.from(userData),
        'id': userId,
      });

      final updatedAddresses = user.savedAddresses
          .where((addr) => addr.id != addressId)
          .toList();
      final updatedUser = user.copyWith(savedAddresses: updatedAddresses);

      await _database.ref('users/$userId').update({
        'savedAddresses': updatedAddresses.map((addr) => addr.toJson()).toList(),
      });

      return updatedUser;
    } catch (e) {
      debugPrint('Error deleting saved address: $e');
      rethrow;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _database.ref('users/${user.uid}/isAdmin').get();
      
      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        return userData['isAdmin'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
}
