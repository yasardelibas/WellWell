import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';

import 'app.dart';
import 'l10n/language_controller.dart';
import 'theme/theme_controller.dart';

void main() {
  // Initialize the bindings and run the app inside the same zone so zone-specific
  // configuration stays consistent (avoids the "Zone mismatch" framework warning).
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      // WellWell is a portrait-only experience; locking orientation prevents the
      // sideways/overflowing layout seen when the device is rotated to landscape.
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      // Medication data is sensitive: block screenshots (Android FLAG_SECURE, also
      // hides the app from the recents thumbnail; iOS blanks the captured content)
      // and blur the app-switcher preview on iOS.
      unawaited(ScreenProtector.preventScreenshotOn());
      unawaited(ScreenProtector.protectDataLeakageWithBlur());
      await AppTheme.load();
      await AppLanguage.load();
      runApp(const ProviderScope(child: WellWellApp()));
    },
    (error, stack) {
      debugPrint('WellWell uncaught: $error\n$stack');
    },
  );
}
