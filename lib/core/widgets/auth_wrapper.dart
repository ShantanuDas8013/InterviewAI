import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/0_splash/presentation/splash_screen.dart';
import '../../features/1_auth/presentation/screens/welcome_screen.dart';
import '../../features/2_home/presentation/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isInitialized = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _setupAuthListener();
  }

  void _initializeAuth() {
    setState(() {
      _currentUser = _supabase.auth.currentUser;
      _isInitialized = true;
    });
  }

  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (mounted) {
        setState(() {
          _currentUser = session?.user;
        });

        // Handle different auth events
        switch (event) {
          case AuthChangeEvent.signedIn:
            // User just signed in, navigate to home
            if (_currentUser != null) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            }
            break;
          case AuthChangeEvent.signedOut:
            // User signed out, navigate to welcome
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/welcome', (route) => false);
            break;
          case AuthChangeEvent.tokenRefreshed:
            // Token was refreshed, user is still authenticated
            debugPrint('Token refreshed for user: ${_currentUser?.email}');
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing
    if (!_isInitialized) {
      return const SplashScreen();
    }

    // If user is authenticated, show home screen
    if (_currentUser != null) {
      return const HomeScreen();
    }

    // If user is not authenticated, show welcome screen
    return const WelcomeScreen();
  }
}
