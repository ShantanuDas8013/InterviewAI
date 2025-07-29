import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/theme.dart';

class ProfileSidebarDrawer extends StatefulWidget {
  final String? userName;
  final String? profilePictureUrl;
  final VoidCallback onProfileUpdated;

  const ProfileSidebarDrawer({
    super.key,
    required this.userName,
    required this.profilePictureUrl,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileSidebarDrawer> createState() => _ProfileSidebarDrawerState();
}

class _ProfileSidebarDrawerState extends State<ProfileSidebarDrawer>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 300, 0),
          child: Drawer(
            backgroundColor: const Color(0xFF1A1A2E),
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(children: [_buildProfileHeader(), _buildMenuItems()]),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 290, // Reduced height to prevent overflow
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16213E),
            Color(0xFF0F3460),
            Color(0xFF533483),
            Color(0xFF8E44AD),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ), // Reduced vertical padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only needed space
            children: [
              _buildHeaderActions(),
              const SizedBox(height: 12), // Reduced spacing
              _buildProfilePicture(),
              const SizedBox(height: 12), // Reduced spacing
              _buildUserInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Hero(
      tag: 'profile_picture',
      child: Container(
        width: 85, // Reduced size
        height: 85, // Reduced size
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ), // Reduced border width
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15, // Reduced blur
              offset: const Offset(0, 6), // Reduced offset
            ),
          ],
        ),
        child: ClipOval(
          child: widget.profilePictureUrl != null
              ? Image.network(
                  widget.profilePictureUrl!,
                  width: 85,
                  height: 85,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingAvatar();
                  },
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor.withOpacity(0.8),
            AppTheme.secondaryAccentColor.withOpacity(0.8),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 38,
      ), // Reduced icon size
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.3),
            AppTheme.secondaryAccentColor.withOpacity(0.3),
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          widget.userName ?? 'User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20, // Reduced font size
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6), // Reduced spacing
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ), // Reduced padding
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16), // Reduced border radius
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Text(
            _supabase.auth.currentUser?.email ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11, // Reduced font size
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Expanded(
      child: Container(
        color: const Color(0xFF1A1A2E),
        child: SingleChildScrollView(
          // Added scroll view to prevent overflow
          padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your information',
                color: AppTheme.accentColor,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(
                    context,
                    '/edit-profile',
                  );
                  if (result == true) {
                    widget.onProfileUpdated();
                  }
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences',
                color: Colors.blueAccent,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings screen coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                subtitle: 'View your progress',
                color: Colors.greenAccent,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analytics screen coming soon!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get assistance',
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help screen coming soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App information',
                color: Colors.cyanAccent,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('About screen coming soon!'),
                      backgroundColor: Colors.cyan,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Reduced spacing
              _buildLogoutSection(),
              const SizedBox(height: 16), // Reduced bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 3,
      ), // Reduced vertical margin
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 18,
            ), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, // Reduced size
                  height: 44, // Reduced size
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Reduced border radius
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ), // Reduced icon size
                ),
                const SizedBox(width: 14), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15, // Reduced font size
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11, // Reduced font size
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showArrow)
                  Container(
                    padding: const EdgeInsets.all(5), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        7,
                      ), // Reduced border radius
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.6),
                      size: 12, // Reduced icon size
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: _buildMenuItem(
        icon: Icons.logout,
        title: 'Sign Out',
        subtitle: 'Logout from app',
        color: Colors.red.shade400,
        showArrow: false,
        onTap: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _signOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
