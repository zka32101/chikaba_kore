# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**近場コレ (Chikaba Kore)** is a Flutter mobile app that connects locals and visitors through location-based facility discovery, reviews, and community features. It uses Firebase for backend infrastructure and Riverpod for state management.

**Key Tech Stack:**
- Flutter 3.47.2 + Dart 3.11+
- Riverpod for state management
- Firebase (Auth, Firestore, Messaging, Crashlytics, Storage)
- Google Maps integration
- Hive for local storage
- Dio for HTTP requests

## Essential Commands

### Build & Run
```bash
# Install dependencies
flutter pub get

# Run app on connected device/emulator
flutter run

# Run release build (Android APK)
flutter build apk --release

# Run release build (Android App Bundle)
flutter build appbundle --release

# Run on iOS (requires macOS)
flutter build ios --release --no-codesign
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/

# Run lints (configured in analysis_options.yaml)
flutter analyze lib/

# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Development
```bash
# Generate code (Riverpod, JSON serialization)
flutter pub run build_runner build

# Watch for changes and regenerate automatically
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

### Firebase Setup
```bash
# The app requires google-services.json for Android builds
# This file is configured via GitHub Secret (GOOGLE_SERVICES_JSON)
# Base64 encode: base64 -i google-services.json
# Base64 decode: echo "<base64-string>" | base64 -d > google-services.json
```

## Architecture

The app follows **Clean Architecture + MVVM pattern**:

```
┌──────────────────────────┐
│   UI Layer (Views)       │  ← screens/, widgets/, dialogs/
├──────────────────────────┤
│  Providers (Riverpod)    │  ← lib/providers/*.dart
├──────────────────────────┤
│  Repositories            │  ← lib/repositories/*.dart
├──────────────────────────┤
│  Services                │  ← lib/services/*.dart
├──────────────────────────┤
│  Data Models             │  ← lib/models/*.dart
└──────────────────────────┘
```

### Directory Structure

- **lib/main.dart** — App entry point, Firebase initialization, Riverpod setup
- **lib/config/** — Router, theme, app configuration
  - `router.dart` — GoRouter navigation setup
  - `theme/app_theme.dart` — Material theme configuration
- **lib/providers/** — Riverpod state management
  - `auth_provider.dart` — Authentication state
  - `facility_provider.dart` — Facility search/filtering
  - `location_provider.dart` — Location & geolocation state
  - `ui_provider.dart` — UI state (filters, sorting, etc.)
- **lib/services/** — Business logic & external integrations
  - `firebase_service.dart` — Firestore, Auth, Messaging
  - `api_service.dart` — Backend API calls (Dio HTTP client)
  - `location_service.dart` — Geolocation via Geolocator
  - `notification_service.dart` — Push notifications setup
  - `cache_service.dart` — Hive local storage
- **lib/models/** — Data classes (generated JSON serialization)
- **lib/views/screens/** — Screen widgets (full-page views)
- **lib/views/widgets/** — Reusable UI components
- **lib/utils/** — Utility functions (logger, extensions, validators)

## State Management (Riverpod)

All state is managed via **Riverpod providers** in `lib/providers/`. Key patterns:

### Basic Provider (computed state)
```dart
final searchQueryProvider = StateProvider<String>((ref) => '');
```

### StateNotifier (mutable state with methods)
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
```

### FutureProvider (async data with auto-refresh)
```dart
final facilityProvider = FutureProvider.autoDispose
  .family<List<Facility>, SearchQuery>((ref, query) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.searchFacilities(query);
});
```

**Important:** Use `.autoDispose` for providers that fetch remote data to prevent memory leaks. Use `.family` to parameterize providers.

## Firebase Integration

- **Authentication** — Firebase Auth (email + Google Sign-In)
- **Database** — Firestore collections:
  - `facilities` — Facility info, ratings, metadata
  - `reviews` — User reviews with images
  - `users` — User profiles, preferences
  - `favorites` — User's "wants to visit" / "going now" tags
- **Messaging** — Firebase Cloud Messaging for push notifications
- **Storage** — Firebase Storage for user avatars and review images
- **Crashlytics** — Automatic crash reporting

Firestore security rules are in `firestore.rules` (when available).

## Common Workflows

### Adding a New Feature
1. **Create data model** in `lib/models/` with `@JsonSerializable()`
2. **Create provider** in `lib/providers/` for state management
3. **Create repository** in `lib/repositories/` for data access
4. **Create screen/widget** in `lib/views/` to display data
5. **Update router** in `lib/config/router.dart` if new screen
6. **Run code generation**: `flutter pub run build_runner build`
7. **Test** with `flutter test`

### Adding a Service (API, location, etc.)
1. Create `lib/services/your_service.dart`
2. Expose via provider: `final yourServiceProvider = Provider((ref) => YourService());`
3. Consume in repositories or providers via `ref.watch(yourServiceProvider)`
4. Add tests in `test/services/` if complex logic

### Debugging
```bash
# View detailed logs
flutter run -v

# Break on exceptions
# In VS Code: add breakpoints in .dart files, run with debugger
flutter run

# Profile performance
flutter run --profile

# Check widget tree
# Use DevTools: flutter pub global activate devtools && devtools
```

## Testing

Current test setup uses Flutter's built-in test framework. Add tests to `test/` directory following `test/widget_test.dart` pattern.

```bash
# Run all tests
flutter test

# Run with specific pattern
flutter test -k "auth"

# Generate coverage report
flutter test --coverage
```

## Important Notes

1. **Environment Variables** — App loads `.env` at startup via `flutter_dotenv`. Key variables:
   - `API_BASE_URL` — Backend API endpoint
   - `MAPS_API_KEY` — Google Maps API key (Android-specific)

2. **Code Generation** — Run `flutter pub run build_runner build` after:
   - Adding `@JsonSerializable()` to models
   - Adding `@riverpod` to functions in Riverpod 2.x syntax
   - Modifying Riverpod generator annotations

3. **Firebase Config** — Android requires `google-services.json` in `android/app/`. This file is not in the repo (security); it's injected via GitHub Secret during CI builds.

4. **Git Workflow** — When pushing changes:
   - Format code: `dart format lib/`
   - Run analyzer: `flutter analyze`
   - Test: `flutter test`
   - Commit with clear messages

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically:
- Runs `flutter analyze` (lint check)
- Runs `flutter test` (unit/widget tests)
- Builds release APK/AAB for Android
- Builds release IPA for iOS (artifacts only)
- Restores `google-services.json` from `GOOGLE_SERVICES_JSON` GitHub Secret
- Publishes releases to GitHub Releases

**Triggering CI:** Push a tag like `v1.0.0` or manually run workflow_dispatch in Actions.

## Useful Links

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase for Flutter](https://firebase.flutter.dev)
- Repository: [zka32101/chikaba_kore](https://github.com/zka32101/chikaba_kore)
