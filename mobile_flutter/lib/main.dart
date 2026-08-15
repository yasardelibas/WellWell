import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Initialize the bindings and run the app inside the same zone so zone-specific
  // configuration stays consistent (avoids the "Zone mismatch" framework warning).
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      // MedGuard is a portrait-only experience; locking orientation prevents the
      // sideways/overflowing layout seen when the device is rotated to landscape.
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      runApp(const ProviderScope(child: MedGuardApp()));
    },
    (error, stack) {
      debugPrint('MedGuard uncaught: $error\n$stack');
    },
  );
}
