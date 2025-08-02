
# GEMINI.md - AI Voice Interview App

## Project Overview

This is a Flutter application designed to help users practice and improve their interview skills. It uses AI and voice technologies to simulate real-world interview experiences.

**Key Features:**

*   **AI-Powered Interviews:** Conducts mock interviews using natural language processing and voice recognition.
*   **Voice Interaction:** Allows users to answer questions verbally.
*   **Resume Analysis:** Users can upload their resume for AI-driven feedback.
*   **Performance Feedback:** Provides detailed feedback on interview answers.
*   **User Authentication:** Secure sign-up and login.

**Core Technologies:**

*   **Frontend:** Flutter
*   **Backend & Database:** Supabase (Authentication, Database, Storage)
*   **AI & Machine Learning:** Google Gemini API
*   **State Management:** BLoC
*   **Routing:** go_router
*   **Audio Processing:** flutter_sound, speech_to_text

## Building and Running

### Prerequisites

*   Flutter SDK
*   Dart SDK
*   Android Studio or Xcode
*   A Supabase project

### Setup & Execution

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/ShantanuDas8013/InterviewAI.git
    cd ai_voice_interview_app
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Configure Supabase:**
    *   Follow the instructions in `SUPABASE_SETUP_GUIDE.md`.
    *   Create a `.env` file in the root directory and add your Supabase credentials and Gemini API key. You can use `.env.example` as a template.

4.  **Run the app:**
    ```sh
    flutter run
    ```

### Testing

To run tests, execute the following command:

```sh
flutter test
```

## Development Conventions

*   **State Management:** The project uses the **BLoC (Business Logic Component)** pattern for state management, as indicated by the `flutter_bloc` dependency. New features should follow this pattern.
*   **Directory Structure:** The `lib` directory is organized by features (e.g., `lib/features/1_auth`, `lib/features/2_home`). Core, shared components are located in `lib/core`.
*   **Routing:** Navigation is handled by the `go_router` package. Route definitions can be found within the feature directories.
*   **Dependencies:** Manage dependencies in the `pubspec.yaml` file. After making changes, run `flutter pub get`.
*   **Code Style:** The project follows the linting rules defined in `analysis_options.yaml`.
*   **Environment Variables:** API keys and other secrets are managed through a `.env` file. Do not commit this file to version control.
