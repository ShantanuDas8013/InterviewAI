# Splash Screen Documentation

## Overview

The splash screen is the first screen users see when launching the AI Voice Interview App. It serves as a loading screen while the app initializes services and checks authentication status.

## Features

### 🎨 **Visual Design**

- **Gradient Background**: Uses the app's primary gradient (Indigo 900 to Darker Indigo)
- **Animated Logo**: Microphone icon with pulsing animation and wave rings
- **Brand Identity**: "Interview AI" title with tagline "Your AI Interview Co-Pilot"
- **Loading Indicators**: Animated dots with "Initializing AI Engine..." message

### ⚡ **Animations**

1. **Pulse Animation**: Logo breathing effect (2-second cycle)
2. **Wave Rings**: Expanding circular waves around the logo (3-second cycle)
3. **Fade-in Effect**: Smooth entrance animation for all elements
4. **Loading Dots**: Three colored dots with staggered pulsing

### 🔄 **Functionality**

- **Minimum Display Time**: 3 seconds to ensure smooth user experience
- **Authentication Check**: Automatically detects if user is logged in
- **Smart Navigation**: Routes to appropriate screen based on auth status
- **Error Handling**: Gracefully handles initialization errors

## File Structure

```
lib/features/0_splash/
└── presentation/
    └── splash_screen.dart
```

## Implementation Details

### Components

1. **SplashScreen** (Main Widget)

   - Handles app initialization
   - Manages navigation logic
   - Checks authentication status

2. **AnimatedSplashUI** (UI Component)

   - Contains all visual elements
   - Manages multiple animation controllers
   - Provides smooth entrance effects

3. **\_WaveRingsPainter** (Custom Painter)
   - Creates animated wave rings
   - Handles multiple wave configurations
   - Provides glow effects

### Navigation Logic

```dart
// After 3-second delay
if (currentUser != null) {
    Navigator.pushReplacementNamed(context, '/home');
} else {
    Navigator.pushReplacementNamed(context, '/welcome');
}
```

### Animation Controllers

- **Pulse Controller**: 2-second repeating animation for logo pulse
- **Wave Controller**: 3-second repeating animation for wave rings
- **Fade Controller**: 1.5-second one-time animation for entrance effect

## Integration with Auth System

The splash screen integrates seamlessly with the `AuthWrapper`:

1. **App Launch**: `main.dart` → `AuthWrapper`
2. **Auth Check**: `AuthWrapper` shows splash while initializing
3. **Navigation**: Based on authentication status:
   - ✅ **Authenticated**: Direct to Home Screen
   - ❌ **Not Authenticated**: Direct to Welcome Screen

## Customization

### Colors

All colors are defined in `AppTheme` class:

```dart
- Primary: Color(0xFF1a237e) // Indigo 900
- Accent: Color(0xFF7C4DFF) // Deep Purple Accent
- Secondary: Color(0xFF536DFE) // Indigo Accent
```

### Timing

```dart
- Minimum display: 3 seconds
- Pulse animation: 2 seconds
- Wave animation: 3 seconds
- Fade-in: 1.5 seconds
```

### Text Content

```dart
- App Title: "Interview AI"
- Tagline: "Your AI Interview Co-Pilot"
- Subtitle: "Practice • Analyze • Improve"
- Loading: "Initializing AI Engine..."
```

## Performance Considerations

- **Efficient Animations**: Uses `AnimatedBuilder` for optimal performance
- **Memory Management**: Proper disposal of animation controllers
- **State Management**: Checks `mounted` before navigation
- **Error Handling**: Fallback navigation on initialization failure

## Accessibility

- **Screen Reader**: Semantic labels for UI elements
- **High Contrast**: Clear visual hierarchy with sufficient contrast
- **Animation Sensitivity**: Considers users with motion sensitivity
- **Loading Feedback**: Clear indication of app initialization progress

## Future Enhancements

- [ ] Add sound effects for premium experience
- [ ] Implement progress indicator for initialization steps
- [ ] Add offline mode detection and handling
- [ ] Include app update check and notification
- [ ] Add seasonal themes or special event variations
