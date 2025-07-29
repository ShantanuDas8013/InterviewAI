import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  // Register user
  Future<User?> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      return response.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in user
  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out user
  Future<void> signOutUser() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _authService.currentUser;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _authService.isLoggedIn;
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  // Update user profile
  Future<User?> updateUserProfile({
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _authService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        additionalData: additionalData,
      );
      return response.user;
    } catch (e) {
      rethrow;
    }
  }

  // Get user metadata
  Map<String, dynamic>? getUserMetadata() {
    return _authService.userMetadata;
  }

  // Get user email
  String? getUserEmail() {
    return _authService.userEmail;
  }

  // Get user full name
  String? getUserFullName() {
    return _authService.userFullName;
  }

  // Check if email is confirmed
  bool isEmailConfirmed() {
    return _authService.isEmailConfirmed;
  }
}
