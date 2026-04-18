import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/clinic_locator/providers/clinic_locator_provider.dart';
import 'features/health_records/providers/health_records_provider.dart';
import 'features/symptom_checker/providers/symptom_checker_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/reminders/providers/reminders_provider.dart';

/// [MboaHealthApp] is the root widget of the application.
///
/// Responsibilities:
/// - Registers all app-level [Provider]s via [MultiProvider].
/// - Configures [MaterialApp] with the design-system theme, routes,
///   and locale settings.
///
/// Design system: "Clinical Sanctuary" — green-centric, editorial, premium.
class MboaHealthApp extends StatelessWidget {
  const MboaHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => HealthRecordsProvider()),
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => ClinicLocatorProvider()),
        ChangeNotifierProvider(create: (_) => SymptomCheckerProvider()),
      ],
      child: MaterialApp(
        // ── Identity ───────────────────────────────────────────────────────
        title: 'Mboa Health',
        debugShowCheckedModeBanner: false,

        // ── Theme ─────────────────────────────────────────────────────────
        theme: AppTheme.light,
        // darkTheme will be added in a later phase.

        // ── Routing ───────────────────────────────────────────────────────
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        onUnknownRoute: AppRoutes.onUnknownRoute,

        // ── Locale ────────────────────────────────────────────────────────
        // Mboa Health targets Cameroon; default locale en.
        // French (fr) support added in Phase 6 (i18n).
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('en'), // English
          Locale('fr'), // French (Cameroon)
        ],
      ),
    );
  }
}
