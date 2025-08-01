import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/0_splash/presentation/splash_screen.dart';
import 'features/1_auth/presentation/screens/welcome_screen.dart';
import 'features/1_auth/presentation/screens/login_screen.dart';
import 'features/1_auth/presentation/screens/registration_screen.dart';
import 'features/2_home/presentation/home_screen.dart';
import 'features/3_profile/presentation/edit_profile_screen.dart';
import 'features/4_resume_upload/presentation/screens/upload_resume_screen.dart';
import 'features/5_interview/presentation/screens/interview_setup_screen.dart';
import 'interview_demo_screen.dart';
import 'core/constants/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Handle case where .env file doesn't exist
    debugPrint('Could not load .env file: $e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Voice Interview App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.primaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.textPrimaryColor,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(), // Start with splash screen
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/upload-resume': (context) => const UploadResumeScreen(),
        '/interview-setup': (context) => const InterviewSetupScreen(),
        '/interview-demo': (context) => const InterviewDemoScreen(),
      },
    );
  }
}
