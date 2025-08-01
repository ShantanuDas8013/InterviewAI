# Speech to Text Plugin Fix

This directory contains a fix for the `speech_to_text` plugin (version 6.6.2) that addresses Kotlin compilation errors related to the Android embedding API.

## The Issue

The error occurs because the plugin is using the deprecated Flutter Android embedding v1 API (`Registrar`) while the project is using the newer embedding v2 API. The specific errors are:

```
Unresolved reference 'Registrar'
Unresolved reference 'activity'
Unresolved reference 'addRequestPermissionsResultListener'
Unresolved reference 'context'
Unresolved reference 'messenger'
```

## The Fix

The patch replaces the plugin's Kotlin implementation with a version that uses the Flutter embedding v2 API, implementing the `FlutterPlugin`, `ActivityAware`, and `PluginRegistry.RequestPermissionsResultListener` interfaces properly.

## How to Apply the Fix

### Option 1: Run the PowerShell Script (Windows)

1. Open PowerShell as Administrator
2. Navigate to the patches directory
3. Run the script:

```powershell
.\apply_speech_to_text_patch.ps1
```

4. Clean and rebuild your Flutter project:

```bash
flutter clean
flutter pub get
flutter run
```

### Option 2: Manual Application

1. Locate the speech_to_text plugin in your Pub cache:
   - Windows: `%USERPROFILE%\AppData\Local\Pub\Cache\hosted\pub.dev\speech_to_text-6.6.2\`
   - macOS/Linux: `~/.pub-cache/hosted/pub.dev/speech_to_text-6.6.2/`

2. Replace the file at `android/src/main/kotlin/com/csdcorp/speech_to_text/SpeechToTextPlugin.kt` with the `speech_to_text_plugin_fix.kt` file from this directory.

3. Clean and rebuild your Flutter project:

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative Solution

If the patch doesn't work, you can also try updating your `pubspec.yaml` to use a newer version of the speech_to_text plugin that supports Flutter embedding v2 natively:

```yaml
dependencies:
  speech_to_text: ^6.6.3  # or the latest version
```

Then run:

```bash
flutter pub get
flutter run
```