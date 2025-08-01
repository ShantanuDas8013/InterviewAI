# AI Voice Interview App

An advanced Flutter application that leverages AI and voice technologies to simulate real-world interview experiences. This app is designed to help users practice and improve their interview skills through interactive, voice-based mock interviews, resume analysis, and instant feedback.

## Features

- **AI-Powered Interviewer:** Conducts interviews using natural language processing and voice recognition.
- **Voice Interaction:** Users can answer questions verbally, simulating a real interview environment.
- **Resume Upload & Analysis:** Upload your resume for instant AI-driven feedback and suggestions.
- **Interview Feedback:** Get detailed feedback on your answers, including strengths and areas for improvement.
- **Multiple Interview Types:** Practice for different roles and industries with customizable question sets.
- **User Registration & Authentication:** Secure sign-up and login functionality.
- **Integration with Supabase:** For backend, authentication, and storage.

## Screenshots

<!-- Add screenshots of your app here -->

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart SDK (comes with Flutter)
- Android Studio or Xcode (for mobile emulation)
- A Supabase account and project (see `SUPABASE_SETUP_GUIDE.md`)

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/ShantanuDas8013/InterviewAI.git
   cd ai_voice_interview_app
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Supabase:**

   - Follow the steps in `SUPABASE_SETUP_GUIDE.md` to set up your Supabase backend and update your environment variables or config files as needed.

4. **Run the app:**
   ```sh
   flutter run
   ```

## Usage

1. Register or log in to your account.
2. Upload your resume for analysis or skip to start a mock interview.
3. Answer interview questions verbally. The AI will listen and provide feedback.
4. Review your performance and suggestions for improvement.

## Project Structure

- `lib/` - Main Dart source code
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - Platform-specific code
- `test/` - Unit and widget tests
- `patches/` - Fixes and plugin patches
- `*.md` - Documentation and guides

## Documentation

- [SUPABASE_SETUP_GUIDE.md](SUPABASE_SETUP_GUIDE.md)
- [DATABASE_SCHEMA.md](database_schema.md)
- [INTERVIEW_SYSTEM_IMPLEMENTATION.md](INTERVIEW_SYSTEM_IMPLEMENTATION.md)
- [RESUME_UPLOAD_FEATURE_DOCS.md](RESUME_UPLOAD_FEATURE_DOCS.md)
- [HOMESCREEN_FIX_GUIDE.md](HOMESCREEN_FIX_GUIDE.md)
- [SPLASH_SCREEN_DOCS.md](SPLASH_SCREEN_DOCS.md)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please open an issue on the [GitHub repository](https://github.com/ShantanuDas8013/InterviewAI).
