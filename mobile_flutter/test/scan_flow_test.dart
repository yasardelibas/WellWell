// Exercises the manual-entry scan path (Api.scan -> Api.confirmScan) against a real local
// backend. Camera capture itself cannot be exercised here: iOS Simulators (and CI) have no
// physical camera, so `availableCameras()` legitimately returns an empty list and
// ScanScreen shows its "no camera available" message - that is a platform limitation, not
// app code, and is covered separately by manual review of _startCamera() in
// lib/screens/scan_screens.dart. This test instead proves the rest of the scan pipeline
// (the part that IS testable outside a real device) round-trips correctly end to end,
// including client-side JSON parsing of the response models.
//
// Run with:
//   flutter test --dart-define=API_BASE_URL=http://localhost:5175 test/scan_flow_test.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellwell/services/api.dart';
import 'package:wellwell/widgets/ui.dart' show demoLabel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test installs an HttpOverrides that fakes every dart:io HttpClient response as a
  // 400 with no real request sent, to stop widget/unit tests from silently hitting the network.
  // This suite's whole point is to hit the real local backend, so opt back into real sockets.
  HttpOverrides.global = null;

  // apiClient.persistTokens() writes through flutter_secure_storage's platform channel, which
  // has no implementation on the host running `flutter test`.
  final secureStorage = <String, String>{};
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return secureStorage[(call.arguments as Map)['key'] as String];
        case 'write':
          final args = call.arguments as Map;
          secureStorage[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          secureStorage.remove((call.arguments as Map)['key'] as String);
          return null;
        default:
          return null;
      }
    },
  );

  test('manual OCR text scan -> confirm produces a saved, safety-checked medication', () async {
    final auth = await Api.demoLogin();
    await apiClient.persistTokens(auth.accessToken, auth.refreshToken);

    final scan = await Api.scan({'ocrText': demoLabel});
    expect(scan.status, isNot('extraction_failed'), reason: 'the sample label should always extract');
    expect(scan.candidates, isNotEmpty, reason: 'the local drug dataset should match the sample Parol label');

    final best = scan.candidates.first;
    final outcome = await Api.confirmScan(scan.scanId, {
      'selectedCandidateRxCui': best.rxCui,
      'brandName': best.brandName,
      'genericName': best.genericName,
      'ingredients': best.ingredients.map((i) => {'name': i.name, 'strength': i.strength, 'unit': i.unit}).toList(),
      'dosageForm': best.dosageForm,
      'strength': best.strength,
      'route': null,
      'labelDirections': scan.field('directions'),
      'acknowledgedUnverified': false,
    });

    expect(outcome.medication.verificationStatus.toLowerCase(), 'verified');
    expect(outcome.safety.findings, isA<List>());
  });
}
