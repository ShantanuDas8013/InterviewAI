import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/theme.dart';
import '../../../core/services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentProfilePicUrl;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _userId = user.id;

        // Get profile from database
        final userProfile = await _databaseService.getUserProfile(user.id);

        if (mounted) {
          setState(() {
            _fullNameController.text =
                userProfile?['full_name'] ??
                user.userMetadata?['full_name'] ??
                '';
            _emailController.text = user.email ?? '';
            _currentProfilePicUrl = userProfile?['profile_picture_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load profile information');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<String?> _uploadProfilePicture() async {
    if (_selectedImage == null || _userId == null) return null;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = '$_userId/profile.jpg'; // Use user ID folder structure

      // Delete existing profile picture if it exists
      try {
        await _supabase.storage.from('profile-pictures').remove([fileName]);
      } catch (e) {
        // Ignore error if file doesn't exist
        debugPrint('No existing profile picture to delete: $e');
      }

      // Upload new profile picture
      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true, // Allow overwriting existing files
            ),
          );

      final publicUrl = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload profile picture');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() => _isSaving = true);
    try {
      String? profilePicUrl = _currentProfilePicUrl;

      // Upload new profile picture if selected
      if (_selectedImage != null) {
        profilePicUrl = await _uploadProfilePicture();
      }

      // Update profile in database
      await _databaseService.updateUserProfile(
        userId: _userId!,
        fullName: _fullNameController.text.trim(),
        profilePictureUrl: profilePicUrl,
      );

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully');
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate profile was updated
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentColor, width: 3),
            ),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : _currentProfilePicUrl != null
                  ? Image.network(
                      _currentProfilePicUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.accentColor,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.accentColor,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            style: TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: enabled
                  ? AppTheme.textPrimaryColor
                  : AppTheme.textSecondaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: enabled
                    ? AppTheme.accentColor
                    : AppTheme.textSecondaryColor,
              ),
              filled: true,
              fillColor: enabled
                  ? AppTheme.cardBackgroundColor
                  : AppTheme.cardBackgroundColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Profile Picture Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.paddingL),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardBorderRadius,
                            ),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              _buildProfilePicture(),
                              const SizedBox(height: 16),
                              Text(
                                'Tap camera icon to change photo',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSmall,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Form Fields Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.paddingL),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardBorderRadius,
                            ),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Full name is required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Full name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),

                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hint: 'Your email address',
                                icon: Icons.email,
                                enabled: false, // Email editing disabled
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Saving...',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeRegular,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeRegular,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
