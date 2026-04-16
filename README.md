# Mboa Health — Developer Documentation

> **Your Smart Health Guide.** A premium concierge health app for Cameroon.  
> Built with Flutter · Dart · Provider · Material Design 3

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Design System — Clinical Sanctuary](#3-design-system--clinical-sanctuary)
4. [Architecture](#4-architecture)
5. [Project Structure](#5-project-structure)
6. [Navigation & Routes](#6-navigation--routes)
7. [Screens Reference](#7-screens-reference)
8. [Shared Components](#8-shared-components)
9. [Getting Started](#9-getting-started)
10. [Development Workflow](#10-development-workflow)

---

## 1. Project Overview

Mboa Health is a full-featured mobile health application targeting users in Cameroon. It acts as a smart health companion providing:

- **Symptom checking** with AI-driven analysis and care recommendations
- **Clinic discovery** with GPS-based locator and detailed clinic profiles
- **Health records management** — scan, digitize, and store medical documents
- **Medication & appointment reminders** with customizable schedules
- **Emergency portal** for rapid ambulance/emergency access
- **Patient profile** with health metrics, medication history, and account management

| Item | Value |
|---|---|
| Package ID | `com.mboahealth.mboa_health` |
| Version | `1.0.0+1` |
| Flutter SDK | `≥ 3.38.7` |
| Dart SDK | `^3.10.7` |
| Min Android API | 21 (Android 5.0) |
| Target Android API | 33 (Android 13) |

---

## 2. Tech Stack

| Dependency | Version | Purpose |
|---|---|---|
| `flutter` | stable | UI framework |
| `provider` | `^6.1.2` | State management (ChangeNotifier + MultiProvider) |
| `google_fonts` | `^6.2.1` | Manrope (Display/Headline) + Inter (Body/Label) |
| `go_router` | `^14.8.1` | Declarative navigation (imported but `Navigator.pushNamed` used for simplicity) |
| `equatable` | `^2.0.5` | Value equality for domain models |
| `cupertino_icons` | `^1.0.8` | Additional iOS-style icons |
| `flutter_lints` | `^6.0.0` (dev) | Strict lint rules (`analysis_options.yaml`) |

---

## 3. Design System — Clinical Sanctuary

The entire UI follows a proprietary design system called **"Clinical Sanctuary"** — clean, airy, and medically trustworthy.

### 3.1 Color Tokens (`lib/core/constants/app_colors.dart`)

| Token | Hex | Usage |
|---|---|---|
| `AppColors.primary` | `#00450D` | CTAs, icons, active states |
| `AppColors.secondary` | `#006E1C` | Supporting actions, status indicators |
| `AppColors.primaryContainer` | `#1B5E20` | Gradient endpoint, hero banners |
| `AppColors.secondaryContainer` | `#98F994` | Pill badges, status chips |
| `AppColors.tertiaryContainer` | `#A70515` | Urgency/warning banners |
| `AppColors.surface` | `#F9F9F9` | Page background |
| `AppColors.surfaceContainerLowest` | `#FFFFFF` | Elevated cards |
| `AppColors.surfaceContainerLow` | `#F3F3F3` | Grouping containers |
| `AppColors.surfaceContainerHigh` | `#E8E8E8` | Secondary interactive elements |
| `AppColors.onSurface` | `#1A1C1C` | Primary text ("soft ink", never pure black) |
| `AppColors.onSurfaceVariant` | `#41493E` | Secondary / caption text |
| `AppColors.primaryFixed` | `#ACF4A4` | Icon container backgrounds |
| `AppColors.outline` | `#717A6D` | Borders, dividers |
| `AppColors.outlineVariant` | `#C0C9BB` | Subtle borders |

**Primary CTA Gradient** (135° linear):
```dart
AppColors.primaryGradient  // Color(0xFF00450D) → Color(0xFF1B5E20)
```

> **Rule:** Never use flat `Color(0xFF00450D)` for primary buttons. Always use `AppColors.primaryGradient`.  
> **Rule:** Boundaries are defined by tonal surface shifts, not 1px borders.

### 3.2 Typography (`lib/core/constants/app_typography.dart`)

| Scale | Font | Weight | Usage |
|---|---|---|---|
| `displayLg/Md/Sm` | Manrope | 800 | Hero headlines |
| `headlineLg/Md/Sm` | Manrope | 700 | Section titles |
| `titleLg/Md/Sm` | Manrope | 600–700 | Card headers, list items |
| `bodyLg/Md/Sm` | Inter | 400–500 | Body copy, descriptions |
| `labelLg/Md/Sm` | Inter | 600–700 | Chips, badges, tags, buttons |

### 3.3 Spacing Grid (`lib/core/constants/app_spacing.dart`)

All spacing is based on an **8pt grid**. Key tokens:

| Token | Value | Description |
|---|---|---|
| `AppSpacing.xs2` | 2dp | Hairline gap |
| `AppSpacing.sm` | 8dp | Compact gap |
| `AppSpacing.base` | 16dp | Standard gap |
| `AppSpacing.xl` | 24dp | Section padding |
| `AppSpacing.xl2` | 32dp | Large section gap |
| `AppSpacing.screenHorizontal` | 24dp | Standard screen side padding |
| `AppSpacing.radiusXl` | 24dp | Buttons, input fields |
| `AppSpacing.radiusXxl` | 32dp | Cards, bottom sheets |
| `AppSpacing.radiusFull` | 9999dp | Pill shapes |

### 3.4 Elevation Model

Rather than Material shadows, elevation is expressed as **tonal surface shifts**:

```
surfaceContainerLowest (white)  ← floating cards
surfaceContainerLow             ← contained sections
surfaceContainerHigh            ← secondary interactive
surface (F9F9F9)                ← page background
```

---

## 4. Architecture

### 4.1 Pattern

The app uses a **feature-first layered architecture**:

```
lib/
├── main.dart              — App entry point, MultiProvider setup
├── app.dart               — MaterialApp root, theme injection
├── core/                  — Framework-level code
│   ├── constants/         — AppColors, AppSpacing, AppTypography
│   ├── routing/           — AppRoutes (named routes map)
│   └── theme/             — AppTheme (ThemeData factory)
├── features/              — One folder per product feature
│   └── <feature>/
│       ├── <screen>.dart  — Screen widget (StatelessWidget or StatefulWidget)
│       └── <sub>/         — Sub-screens branching from main feature
└── shared/
    └── widgets/           — Reusable design-system widgets
```

### 4.2 State Management

- **Provider** (`^6.1.2`) via `MultiProvider` in `main.dart`
- Each domain area will have its own `ChangeNotifier` (e.g. `AuthNotifier`, `RecordsNotifier`)
- Screen state (form inputs, toggles) lives in `StatefulWidget` — not lifted unless shared

### 4.3 Navigation

All navigation uses `Navigator.pushNamed` / `pushNamedAndRemoveUntil` with the centralized `AppRoutes` constant class:

```dart
// Navigate forward
Navigator.pushNamed(context, AppRoutes.clinicDetails);

// Navigate and clear stack (after login)
Navigator.pushNamedAndRemoveUntil(
  context, AppRoutes.dashboard, (_) => false,
);
```

---

## 5. Project Structure

```
mboa_health/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_spacing.dart
│   │   │   ├── app_typography.dart
│   │   │   └── constants.dart
│   │   ├── routing/
│   │   │   └── app_routes.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── features/
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart
│   │   ├── role_selection/
│   │   │   └── role_selection_screen.dart
│   │   ├── auth/
│   │   │   ├── login/
│   │   │   │   └── login_screen.dart
│   │   │   └── sign_up/
│   │   │       └── sign_up_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── symptom_checker/
│   │   │   └── symptom_checker_screen.dart
│   │   ├── clinic_locator/
│   │   │   ├── clinic_locator_screen.dart
│   │   │   └── clinic_details/
│   │   │       └── clinic_details_screen.dart
│   │   ├── health_records/
│   │   │   ├── health_records_screen.dart
│   │   │   ├── add_record/
│   │   │   │   └── add_record_screen.dart
│   │   │   └── analysis_result/
│   │   │       └── analysis_result_screen.dart
│   │   ├── emergency/
│   │   │   └── emergency_portal_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── reminders/
│   │   │   ├── reminders_screen.dart
│   │   │   └── add_reminder/
│   │   │       └── add_reminder_screen.dart
│   │   └── notifications/
│   │       └── notifications_screen.dart
│   └── shared/
│       └── widgets/
│           ├── ambient_blob.dart
│           ├── app_card.dart
│           ├── app_input_field.dart
│           ├── gradient_button.dart
│           └── widgets.dart       ← barrel export
├── assets/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 6. Navigation & Routes

All routes are defined in `lib/core/routing/app_routes.dart`.

### User Flow

```
SplashScreen (/)
    └── OnboardingScreen (/onboarding)
            └── RoleSelectionScreen (/role-selection)
                    ├── LoginScreen (/login)
                    │       └── DashboardScreen (/dashboard)  ← clears stack
                    └── SignUpScreen (/sign-up)
                            └── DashboardScreen (/dashboard)  ← clears stack

DashboardScreen (/dashboard)
    ├── SymptomCheckerScreen (/symptom-checker)
    │       └── AnalysisResultScreen (/health-records/analysis-result)
    │               └── ClinicLocatorScreen (/clinic-locator)
    ├── ClinicLocatorScreen (/clinic-locator)
    │       └── ClinicDetailsScreen (/clinic-details)
    ├── HealthRecordsScreen (/health-records)
    │       └── AddRecordScreen (/health-records/add)
    ├── EmergencyPortalScreen (/emergency)
    ├── ProfileScreen (/profile)
    ├── RemindersScreen (/reminders)
    │       └── AddReminderScreen (/reminders/add)
    └── NotificationsScreen (/notifications)
```

### Route Constants

```dart
AppRoutes.splash           = '/'
AppRoutes.onboarding       = '/onboarding'
AppRoutes.roleSelection    = '/role-selection'
AppRoutes.login            = '/login'
AppRoutes.signUp           = '/sign-up'
AppRoutes.dashboard        = '/dashboard'
AppRoutes.symptomChecker   = '/symptom-checker'
AppRoutes.clinicLocator    = '/clinic-locator'
AppRoutes.clinicDetails    = '/clinic-details'
AppRoutes.healthRecords    = '/health-records'
AppRoutes.addRecord        = '/health-records/add'
AppRoutes.analysisResult   = '/health-records/analysis-result'
AppRoutes.emergencyPortal  = '/emergency'
AppRoutes.profile          = '/profile'
AppRoutes.reminders        = '/reminders'
AppRoutes.addReminder      = '/reminders/add'
AppRoutes.notifications    = '/notifications'
```

---

## 7. Screens Reference

| Screen | File | Description | State |
|---|---|---|---|
| `SplashScreen` | `splash/splash_screen.dart` | Animated logo, auto-navigates after 2.5 s | Stateful |
| `OnboardingScreen` | `onboarding/onboarding_screen.dart` | 3-page PageView with hero illustrations | Stateful |
| `RoleSelectionScreen` | `role_selection/role_selection_screen.dart` | Patient / Healthcare Provider role cards | Stateless |
| `LoginScreen` | `auth/login/login_screen.dart` | Email + password form, social auth buttons | Stateful |
| `SignUpScreen` | `auth/sign_up/sign_up_screen.dart` | Full registration form with validation | Stateful |
| `DashboardScreen` | `dashboard/dashboard_screen.dart` | Bento grid layout, animated BottomNavBar | Stateful |
| `SymptomCheckerScreen` | `symptom_checker/symptom_checker_screen.dart` | Multi-step symptom entry, body-part selector | Stateful |
| `ClinicLocatorScreen` | `clinic_locator/clinic_locator_screen.dart` | Map placeholder, nearby clinic list cards | Stateless |
| `ClinicDetailsScreen` | `clinic_locator/clinic_details/` | Clinic hero, Call/Navigate actions, specializations, map | Stateless |
| `HealthRecordsScreen` | `health_records/health_records_screen.dart` | Record list with category filters | Stateless |
| `AddRecordScreen` | `health_records/add_record/` | 4:3 camera upload, form, category dropdown | Stateful |
| `AnalysisResultScreen` | `health_records/analysis_result/` | Diagnosis card, action rows, urgency banner, recommended clinic | Stateless |
| `EmergencyPortalScreen` | `emergency/emergency_portal_screen.dart` | One-tap emergency contacts, ambulance request | Stateless |
| `ProfileScreen` | `profile/profile_screen.dart` | Health metrics, medication history, settings | Stateless |
| `RemindersScreen` | `reminders/reminders_screen.dart` | Reminder list grouped by Today/Upcoming | Stateless |
| `AddReminderScreen` | `reminders/add_reminder/` | Hero banner, title + date/time pickers, frequency chips | Stateful |
| `NotificationsScreen` | `notifications/notifications_screen.dart` | Notification feed grouped by date | Stateless |

---

## 8. Shared Components

Located in `lib/shared/widgets/`. Export all via `widgets.dart`.

### `GradientButton`
Full-width primary CTA button with `AppColors.primaryGradient`, shadow, and loading state.
```dart
GradientButton(
  label: 'Continue',
  icon: Icons.arrow_forward_rounded,
  onPressed: () {},
);
```

### `AppInputField`
Styled `TextFormField` using `surfaceContainerLow` fill, primary focus ring, `radiusXl` border radius.
```dart
AppInputField(
  label: 'Email address',
  hint: 'you@example.com',
  icon: Icons.email_outlined,
  controller: _emailCtrl,
);
```

### `AppCard`
Opinionated `Container` wrapper: `surfaceContainerLowest` background, `radiusXxl` corners, subtle box shadow.
```dart
AppCard(
  child: Text('Card content'),
);
```

### `AmbientBlob`
Decorative blurred gradient circle used in hero sections.
```dart
// Use defaults — do not pass redundant sigma/opacity/alignment params
AmbientBlob(color: AppColors.primaryFixed);
```

---

## 9. Getting Started

### Prerequisites

- Flutter SDK `≥ 3.38.7` (stable channel)
- Dart SDK `^3.10.7`
- Android Studio or VS Code with Flutter extension
- Android emulator (Pixel 4 / API 33 recommended) or physical device

### Clone & Run

```bash
# Clone
git clone https://github.com/claudetomoh/rise_for_impact.git
cd rise_for_impact

# Install dependencies
flutter pub get

# Verify no issues
flutter analyze

# Run on connected device / emulator
flutter run
```

### Run on Specific Device

```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run -d emulator-5554

# Run on physical Android device
flutter run -d <device-id>

# Run on iOS simulator (macOS only)
flutter run -d iPhone
```

### Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 10. Development Workflow

### Linting

The project uses `flutter_lints ^6.0.0` with strict rules (`analysis_options.yaml`). **Zero issues are required before any commit.**

```bash
flutter analyze
# Expected: No issues found!
```

Common rules enforced:
- `prefer_const_constructors` — add `const` where possible
- `avoid_redundant_argument_values` — remove params that match defaults
- `avoid_void_async` — use `Future<void>` return type for async void functions
- `inference_failure_on_instance_creation` — type-annotate `Future<void>.delayed(...)`

### Adding a New Screen

1. Create `lib/features/<feature>/<screen>_screen.dart`
2. Add a named route constant to `AppRoutes`:
   ```dart
   static const String myScreen = '/my-screen';
   ```
3. Add the route to the `routes` map in `AppRoutes`:
   ```dart
   myScreen: (_) => const MyScreen(),
   ```
4. Navigate using:
   ```dart
   Navigator.pushNamed(context, AppRoutes.myScreen);
   ```
5. Run `flutter analyze` — fix all issues before committing.

### Design Conventions

- **Never** use flat `Color(0xFF00450D)` for primary buttons → use `AppColors.primaryGradient`
- **Never** use `#000000` for text → use `AppColors.onSurface`
- All padding/spacing must come from `AppSpacing` constants
- All text styles must come from `AppTypography` constants
- All colors must come from `AppColors` constants
- Screen scaffold: `CustomScrollView` + `SliverAppBar` + `SliverPadding`
- Frosted app bar: `backgroundColor: Colors.white.withValues(alpha: 0.88)`
- Cards use `surfaceContainerLowest` bg + `radiusXxl` corners
- Sections use `surfaceContainerLow` bg + `radiusXxl` corners

### Git Branch

- **Active development branch:** `tubea-sync`
- **Default branch:** `main`
- Repository: `github.com/claudetomoh/rise_for_impact`

---

*Mboa Health — Building healthier communities in Cameroon, one tap at a time.*
