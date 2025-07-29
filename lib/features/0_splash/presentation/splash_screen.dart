import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/theme.dart';

/// Main splash screen widget that handles initialization and navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app services and handle navigation
  Future<void> _initializeApp() async {
    try {
      // Show splash screen for minimum 3 seconds for better UX
      final splashTimer = Future.delayed(const Duration(seconds: 3));

      // Check authentication status while splash is showing
      final currentUser = _supabase.auth.currentUser;

      // Wait for minimum splash time to complete
      await splashTimer;

      if (mounted) {
        // Navigate based on authentication status
        if (currentUser != null) {
          // User is authenticated, go to home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // User is not authenticated, go to welcome
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } catch (e) {
      // Handle initialization errors
      debugPrint('Splash initialization error: $e');
      if (mounted) {
        // Wait minimum time even on error for better UX
        await Future.delayed(const Duration(seconds: 2));
        // Navigate to welcome screen on error
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplashUI();
  }
}

/// Animated UI component for the splash screen
class AnimatedSplashUI extends StatefulWidget {
  const AnimatedSplashUI({super.key});

  @override
  State<AnimatedSplashUI> createState() => _AnimatedSplashUIState();
}

class _AnimatedSplashUIState extends State<AnimatedSplashUI>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Start entrance animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: _buildContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildLogo(),
          const SizedBox(height: AppTheme.paddingL),
          _buildAppTitle(),
          const SizedBox(height: AppTheme.paddingS),
          _buildSlogan(),
          const Spacer(flex: 3),
          _buildLoadingIndicator(),
          const SizedBox(height: AppTheme.paddingXL),
          _buildVersionInfo(),
          const SizedBox(height: AppTheme.paddingM),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = sin(_pulseController.value * 2 * pi);
        final scale = 1.0 + (pulse * 0.05);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated wave rings
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) => CustomPaint(
                    size: const Size(140, 140),
                    painter: _WaveRingsPainter(_waveController.value),
                  ),
                ),
                // Central logo container
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.2),
                    border: Border.all(
                      color: AppTheme.textPrimaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 48,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppTitle() {
    return const Text(
      'Interview AI',
      style: TextStyle(
        fontSize: AppTheme.fontSizeXXLarge + 4,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
        letterSpacing: 2.0,
        shadows: [
          Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildSlogan() {
    return Column(
      children: [
        Text(
          'Your AI Interview Co-Pilot',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.paddingS),
        Text(
          'Practice • Analyze • Improve',
          style: TextStyle(
            fontSize: AppTheme.fontSizeRegular,
            color: AppTheme.textHintColor,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        _buildLoadingDots(),
        const SizedBox(height: AppTheme.paddingM),
        Text(
          'Initializing AI Engine...',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textHintColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            const SizedBox(width: 12),
            _buildDot(1),
            const SizedBox(width: 12),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final colors = [
      Colors.cyanAccent,
      AppTheme.accentColor,
      AppTheme.secondaryAccentColor,
    ];

    final delay = index * 0.3;
    final progress = (_pulseController.value + delay) % 1.0;
    final opacity = 0.3 + (0.7 * (0.5 + 0.5 * sin(progress * 2 * pi)));
    final scale = 0.8 + (0.4 * (0.5 + 0.5 * sin(progress * 2 * pi)));

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: colors[index].withOpacity(opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors[index].withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      'Version 1.0.0',
      style: TextStyle(
        fontSize: AppTheme.fontSizeSmall - 2,
        color: AppTheme.textHintColor,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

/// Custom painter for animated wave rings around the logo
class _WaveRingsPainter extends CustomPainter {
  final double progress;

  _WaveRingsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 50.0;

    // Wave ring configurations
    final waveConfigs = [
      {'delay': 0.0, 'maxRadius': 70.0, 'color': AppTheme.accentColor},
      {
        'delay': 0.33,
        'maxRadius': 65.0,
        'color': AppTheme.secondaryAccentColor,
      },
      {'delay': 0.66, 'maxRadius': 60.0, 'color': Colors.cyanAccent},
    ];

    for (final config in waveConfigs) {
      final delay = config['delay'] as double;
      final maxRadius = config['maxRadius'] as double;
      final color = config['color'] as Color;

      final waveProgress = (progress + delay) % 1.0;
      final radius = baseRadius + (waveProgress * (maxRadius - baseRadius));
      final opacity = (1.0 - waveProgress) * 0.6;

      if (opacity > 0.1) {
        final paint = Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * (1.0 - waveProgress);

        // Add glow effect
        final glowPaint = Paint()
          ..color = color.withOpacity(opacity * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0 * (1.0 - waveProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(center, radius, glowPaint);
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
