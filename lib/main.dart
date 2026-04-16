import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

/// Entry point for Mboa Health.
///
/// Bootstrap steps:
/// 1. Ensures Flutter engine is initialized.
/// 2. Locks orientation to portrait-only.
/// 3. Sets transparent status/nav bars for edge-to-edge rendering.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MboaHealthApp());
}
