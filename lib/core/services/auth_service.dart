import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Register with email and password
  Future<AuthResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'display_name': fullName},
      );

      if (response.user != null) {
        // Update user metadata if needed
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {'full_name': fullName, 'display_name': fullName},
          ),
        );

        // Create user profile entry in the profiles table
        await _createUserProfile(response.user!, fullName, email);
      }

      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Create user profile in the profiles table
  Future<void> _createUserProfile(
    User user,
    String fullName,
    String email,
  ) async {
    try {
      await _databaseService.createUserProfile(
        userId: user.id,
        email: email,
        fullName: fullName,
      );
    } catch (e) {
      // Log error but don't throw - user is already created in auth
      debugPrint('Error creating user profile: $e');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Update user profile
  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (fullName != null) {
        data['full_name'] = fullName;
        data['display_name'] = fullName;
      }

      if (avatarUrl != null) {
        data['avatar_url'] = avatarUrl;
      }

      if (additionalData != null) {
        data.addAll(additionalData);
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );

      return response;
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // Get user profile data
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  // Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    return await _databaseService.getUserProfile(currentUser!.id);
  }

  // Update user profile in database
  Future<Map<String, dynamic>?> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? location,
    String? bio,
    String? experienceLevel,
    String? currentCompany,
    String? currentPosition,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    List<String>? preferredJobRoles,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    return await _databaseService.updateUserProfile(
      userId: currentUser!.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      location: location,
      bio: bio,
      experienceLevel: experienceLevel,
      currentCompany: currentCompany,
      currentPosition: currentPosition,
      linkedinUrl: linkedinUrl,
      githubUrl: githubUrl,
      portfolioUrl: portfolioUrl,
      preferredJobRoles: preferredJobRoles,
    );
  }

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user full name
  String? get userFullName =>
      userMetadata?['full_name'] ?? userMetadata?['display_name'];

  // Check if email is confirmed
  bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;
}
