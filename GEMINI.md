### **Prompt for Gemini CLI**

You are an expert Flutter developer specializing in API integrations. Your task is to refactor an existing Flutter application to use the AssemblyAI API for highly accurate speech-to-text transcription, replacing the current on-device `speech_to_text` package.

The primary goal is to improve transcription quality to get more accurate interview feedback from the Gemini evaluation service.

### **Project Requirements**

1.  **Remove Old Dependency**: The `speech_to_text` package should be removed from `pubspec.yaml`.
2.  **Add New Dependencies**: Add the `http` package for making API calls and a suitable audio recording package like `record` or `flutter_sound`.
3.  **Configuration**: The AssemblyAI API key should be managed securely, ideally loaded from a configuration file or environment variable, not hardcoded.
4.  **New Service**: Create a new Dart service class named `AssemblyAiService` to encapsulate all interactions with the AssemblyAI API.
5.  **UI Integration**: Update the interview screen to handle audio recording and integrate with the new `AssemblyAiService`.

---

### **Implementation Details**

#### **1. `AssemblyAiService` Class**

This service must implement the complete three-step transcription process required by AssemblyAI:

- **Step A: Upload Audio File**

  - Create a method that accepts a local audio file path.
  - It should make a `POST` request to the AssemblyAI endpoint: `https://api.assemblyai.com/v2/upload`.
  - The request header must include the `Authorization` token (your API key).
  - This method should return the secure `upload_url` from the response.

- **Step B: Submit for Transcription**

  - Create a method that takes the `upload_url`.
  - It should make a `POST` request to `https://api.assemblyai.com/v2/transcript`.
  - The request body must be a JSON object containing the `audio_url`.
  - This method should return the `id` of the transcription job.

- **Step C: Poll for Results**
  - Create a method that takes the transcription `id`.
  - This method should make periodic `GET` requests to `https://api.assemblyai.com/v2/transcript/{id}`.
  - It must continue polling until the `status` field in the response is `completed` or `error`.
  - Implement a reasonable delay between polling attempts (e.g., 2-3 seconds).
  - If the status is `completed`, it should extract and return the final `text` from the response.
  - It must handle potential errors by checking for `status: 'error'`.

#### **2. Interview Screen UI and Logic**

- When the user presses the microphone button, the app should start recording audio to a file.
- When the user stops speaking, the recording should be saved.
- The file path of the saved recording should be passed to the `AssemblyAiService`.
- A loading indicator should be displayed to the user while the transcription is in progress.
- Once the final transcript is returned from the service, it should be passed to the existing Gemini API service for evaluation.

---

### **Your Task**

Please provide the complete, production-ready Dart code for the refactored application. Your response should include:

1.  The full code for the new `AssemblyAiService` class, complete with error handling and comments.
2.  The modified code for the interview screen widget, showing the integration of the audio recorder and the new service.
3.  An example of how to correctly call the main transcription method in the UI.

Ensure the code is clean, efficient, and follows Flutter best practices.
