flutter_voice_interview_app/
├── android/ # Android specific files
├── ios/ # iOS specific files
├── assets/ # For all static assets
│ ├── images/ # App logos, background images, etc.
│ │ └── logo.png
│ │ └── welcome_bg.png
│ ├── icons/ # Custom icons
│ │ └── profile_icon.svg
│ └── fonts/ # Custom fonts
│ └── AppFont-Regular.ttf
│
├── lib/ # The heart of your Flutter application
│ ├── main.dart # App entry point, initializes services and routes
│
│ ├── core/ # Shared code used across multiple features
│ │ ├── api/ # API service clients
│ │ │ └── gemini_service.dart
│ │ ├── constants/ # App-wide constants
│ │ │ ├── app_constants.dart # General constants
│ │ │ ├── api_constants.dart # API endpoints and keys
│ │ │ └── theme.dart # App theme, colors, text styles
│ │ ├── models/ # Core data models (e.g., user)
│ │ │ └── user_model.dart
│ │ ├── services/ # Core singleton services
│ │ │ ├── auth_service.dart # Wraps Supabase Auth
│ │ │ ├── database_service.dart # Wraps Supabase database calls
│ │ │ └── storage_service.dart # Wraps Supabase Storage for uploads
│ │ ├── utils/ # Utility functions and helpers
│ │ │ ├── validators.dart
│ │ │ └── pdf_parser.dart
│ │ └── widgets/ # Common, reusable widgets
│ │ ├── custom_button.dart
│ │ ├── loading_indicator.dart
│ │ └── dialogs.dart
│
│ └── features/ # Main folder for all app features
│ ├── 0_splash/ # Splash Screen feature
│ │ └── presentation/
│ │ └── splash_screen.dart
│ │
│ ├── 1_auth/ # Authentication (Login/Register)
│ │ ├── data/
│ │ │ └── auth_repository.dart
│ │ ├── logic/ # State management (e.g., BLoC, Provider)
│ │ │ └── auth_bloc.dart
│ │ └── presentation/ # UI Layer
│ │ ├── screens/
│ │ │ ├── welcome_screen.dart
│ │ │ ├── login_screen.dart
│ │ │ └── register_screen.dart
│ │ └── widgets/
│ │ └── auth_form_field.dart
│ │
│ ├── 2_home/ # Home Screen
│ │ └── presentation/
│ │ ├── home_screen.dart
│ │ └── widgets/
│ │ └── job_role_selector.dart
│ │
│ ├── 3_profile/ # Profile & Edit Profile
│ │ ├── data/
│ │ │ └── profile_repository.dart
│ │ ├── logic/
│ │ │ └── profile_cubit.dart
│ │ └── presentation/
│ │ ├── screens/
│ │ │ └── edit_profile_screen.dart
│ │ └── widgets/
│ │ └── profile_sidebar_drawer.dart # The drawer itself
│ │
│ ├── 4_resume/ # Resume Upload and Analysis
│ │ ├── data/
│ │ │ └── resume_repository.dart
│ │ ├── logic/
│ │ │ └── resume_analysis_bloc.dart
│ │ └── presentation/
│ │ ├── screens/
│ │ │ ├── resume_upload_screen.dart
│ │ │ └── analysis_result_screen.dart
│ │ └── widgets/
│ │ └── file_picker_button.dart
│ │
│ └── 5_interview/ # Interview and Results
│ ├── data/
│ │ ├── models/ # Models specific to interviews
│ │ │ ├── interview_question_model.dart
│ │ │ └── interview_result_model.dart
│ │ └── interview_repository.dart
│ ├── logic/
│ │ └── interview_bloc.dart
│ ├── services/ # Services specific to interviews
│ │ └── speech_to_text_service.dart
│ └── presentation/
│ ├── screens/
│ │ ├── interview_screen.dart
│ │ └── interview_result_screen.dart
│ └── widgets/
│ ├── voice_visualizer.dart
│ ├── question_card.dart
│ └── feedback_section.dart
│
├── pubspec.yaml # Project dependencies and asset declarations
└── README.md # Project documentation
