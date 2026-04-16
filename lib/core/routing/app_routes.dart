import 'package:flutter/material.dart';

import '../../core/security/auth_guard.dart';
// ─── Feature screen imports ───────────────────────────────────────────────
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/sign_up/sign_up_screen.dart';
import '../../features/role_selection/role_selection_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/symptom_checker/symptom_checker_screen.dart';
import '../../features/clinic_locator/clinic_locator_screen.dart';
import '../../features/health_records/health_records_screen.dart';
import '../../features/health_records/add_record/add_record_screen.dart';
import '../../features/health_records/analysis_result/analysis_result_screen.dart';
import '../../features/clinic_locator/clinic_details/clinic_details_screen.dart';
import '../../features/emergency/emergency_portal_screen.dart';
import '../../core/models/clinic_model.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/reminders/add_reminder/add_reminder_screen.dart';
import '../../features/notifications/notifications_screen.dart';

/// Mboa Health — centralized named-route definitions.
///
/// All navigation is done through named routes to keep screens decoupled.
///
/// Usage:
/// ```dart
/// Navigator.pushNamed(context, AppRoutes.login);
/// Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (_) => false);
/// ```
abstract final class AppRoutes {
  // ─── Route name constants ─────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String dashboard = '/dashboard';
  static const String symptomChecker = '/symptom-checker';
  static const String clinicLocator = '/clinic-locator';
  static const String clinicDetails = '/clinic-details';
  static const String healthRecords = '/health-records';
  static const String addRecord = '/health-records/add';
  static const String analysisResult = '/health-records/analysis-result';
  static const String emergencyPortal = '/emergency';
  static const String profile = '/profile';
  static const String reminders = '/reminders';
  static const String addReminder = '/reminders/add';
  static const String notifications = '/notifications';

  // ─── Route map for MaterialApp ────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        onboarding: (_) => const OnboardingScreen(),
        roleSelection: (_) => const RoleSelectionScreen(),
        login: (_) => const LoginScreen(),
        signUp: (_) => const SignUpScreen(),
        dashboard: (_) => const DashboardScreen(),
        symptomChecker: (_) => const SymptomCheckerScreen(),
        clinicLocator: (_) => const ClinicLocatorScreen(),
        healthRecords: (_) => const HealthRecordsScreen(),
        addRecord: (_) => const AddRecordScreen(),
        analysisResult: (_) => const AnalysisResultScreen(),
        emergencyPortal: (_) => const EmergencyPortalScreen(),
        profile: (_) => const ProfileScreen(),
        reminders: (_) => const RemindersScreen(),
        addReminder: (_) => const AddReminderScreen(),
        notifications: (_) => const NotificationsScreen(),
      };

  // ─── Unknown route handler ────────────────────────────────────────────────
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Route "${settings.name}" not found.'),
        ),
      ),
    );
  }

  // ─── Protected routes (require authentication) ────────────────────────────
  static const _protectedRoutes = {
    dashboard,
    symptomChecker,
    clinicLocator,
    clinicDetails,
    healthRecords,
    addRecord,
    analysisResult,
    emergencyPortal,
    profile,
    reminders,
    addReminder,
    notifications,
  };

  /// Generates a [MaterialPageRoute] for [settings], redirecting to [login]
  /// if an unauthenticated user attempts to access a protected route.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (_protectedRoutes.contains(name) && !AuthGuard.isAuthenticated) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: login),
        builder: (_) => const LoginScreen(),
      );
    }
    // Routes requiring typed arguments
    if (name == clinicDetails) {
      final clinic = settings.arguments as Clinic?;
      if (clinic == null) return onUnknownRoute(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ClinicDetailsScreen(clinic: clinic),
      );
    }
    final builder = routes[name];
    if (builder != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: builder,
      );
    }
    return onUnknownRoute(settings);
  }
}
