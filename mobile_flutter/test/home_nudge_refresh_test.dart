// Reproduces and verifies the fix for: after marking a dose taken/skipped on the Home
// screen, the AI-generated nudge message at the top of the screen did not refresh to
// reflect the new completed/total counts - it kept showing whatever was cached, for up
// to 6 hours. Runs against a real local backend (no mocked HTTP), so it exercises the
// actual client<->server contract end to end. Pumps HomeScreen directly (auth state
// injected via a Riverpod override) rather than booting the full app/GoRouter/splash
// chain, which is unrelated to what this test is about and was a source of flakiness.
//
// Run with:
//   flutter test --dart-define=API_BASE_URL=http://localhost:5175 test/home_nudge_refresh_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellwell/l10n/generated/app_localizations.dart';
import 'package:wellwell/screens/tabs.dart';
import 'package:wellwell/services/api.dart';
import 'package:wellwell/state/auth.dart';
import 'package:wellwell/widgets/domain.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter_test fakes every dart:io HttpClient response as a 400 with no real request sent.
  // This test's whole point is to hit the real local backend, so opt back into real sockets.
  HttpOverrides.global = null;

  testWidgets('tapping Take refreshes the nudge instead of reusing the stale cached one', (tester) async {
    // The default test surface is small enough that dose cards below the fold aren't
    // hit-testable without an explicit scroll. Give it a tall canvas instead so everything on
    // Home fits without needing scroll gestures.
    tester.view.physicalSize = const Size(1170, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // apiClient.persistTokens() writes through flutter_secure_storage's platform channel,
    // which has no implementation on the host running `flutter test`.
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

    await tester.runAsync(() async {
      // Sign in for real against the local backend under test.
      final auth = await Api.demoLogin();
      await apiClient.persistTokens(auth.accessToken, auth.refreshToken);

      // Seed a pending dose so a "Take" button actually exists. Every demo dose is normally
      // "taken" once the app has been used a bit, at which point Home shows no actionable
      // button at all - so we create a fresh one, due now, to have something to tap.
      final medications = await Api.medications();
      final subject = medications.firstWhere((m) => m.displayName.toLowerCase().contains('parol'),
          orElse: () => medications.first);
      final now = TimeOfDay.now();
      final nowLabel = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await Api.saveSchedule({
        'medicationId': subject.id,
        'times': [nowLabel],
        'labelInstruction': 'Test dose',
        'doseAmountText': '1 tablet',
        'userConfirmed': true,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _StubAuthNotifier(AuthState(status: AuthStatus.signedIn, user: auth.user))),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      // "Scan Medication" renders unconditionally from frame 0 regardless of load state, so it
      // is not a useful "finished loading" signal - wait for the (indeterminate) loading
      // spinner to go away instead, which only happens once the real Api.today()/Api.findings()
      // calls resolve. The completed/total progress ring is ALSO a CircularProgressIndicator
      // (a determinate one, with a value), so it must be excluded here.
      bool stillLoading() =>
          find.byWidgetPredicate((w) => w is CircularProgressIndicator && w.value == null).evaluate().isNotEmpty;
      await tester.pump();
      for (var i = 0; i < 20 && stillLoading(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      }
      expect(stillLoading(), isFalse, reason: 'expected the Home screen to finish its initial load');
      expect(find.text('Scan Medication'), findsOneWidget, reason: 'expected the Home screen to finish its initial load');

      final takeButtonFinder = find.widgetWithText(FilledButton, 'Take').hitTestable();
      if (takeButtonFinder.evaluate().isEmpty) {
        final texts = find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toList();
        // ignore: avoid_print
        print('DEBUG: all texts: $texts');
        // ignore: avoid_print
        print('DEBUG: FilledButton count: ${find.byType(FilledButton).evaluate().length}, '
            'not-hitTestable Take count: ${find.widgetWithText(FilledButton, 'Take').evaluate().length}');
        fail('No actionable "Take" button found - could not exercise the record() -> nudge refresh path');
      }

      // Capture the nudge shown before recording a dose. The nudge is AI-generated, so two
      // independent calls for the same counts are not guaranteed to produce byte-identical
      // text - comparing before vs. after (rather than against a second live fetch) is what
      // actually proves "it refetched", not "the wording happened to match".
      // _loadNudge() is fire-and-forget from load() (loading flips false before it resolves),
      // so wait for the card to actually appear rather than assuming it's there already.
      for (var i = 0; i < 20 && find.byType(InsightCard).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      }
      expect(find.byType(InsightCard), findsOneWidget, reason: 'expected the initial nudge to have loaded');
      final beforeMessage = tester.widget<InsightCard>(find.byType(InsightCard)).message;

      await tester.tap(takeButtonFinder.first);
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
      }

      expect(find.byType(InsightCard), findsOneWidget, reason: 'expected a nudge card to still be showing after recording a dose');
      final afterMessage = tester.widget<InsightCard>(find.byType(InsightCard)).message;

      expect(
        afterMessage,
        isNot(equals(beforeMessage)),
        reason: 'Home showed the same nudge ("$beforeMessage") after recording a dose - it reused the stale '
            'cached value instead of fetching a fresh one for the new completed/total counts.',
      );
    });
  });
}
