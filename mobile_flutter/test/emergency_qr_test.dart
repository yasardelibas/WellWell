// Isolated check of the one widget behind the "QR code is not working" report:
// EmergencyScreen renders `QrImageView(data: card.shareUrl, size: 220)`
// (lib/screens/extra_screens.dart). This pumps it with a real shareUrl shape
// returned by the local backend and asserts qr_flutter actually paints a code
// instead of falling into its error state.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('QrImageView renders an emergency-card shareUrl without hitting its error state', (tester) async {
    const shareUrl = 'http://localhost:5175/e/iSpc_yS2YI37YLICz21ajo3GFbfYycpu0pioUPreBB0';
    var errorBuilderCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QrImageView(
            data: shareUrl,
            size: 220,
            errorStateBuilder: (context, error) {
              errorBuilderCalled = true;
              return Text('QR error: $error');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(errorBuilderCalled, isFalse, reason: 'qr_flutter fell into its error state for a normal shareUrl');
    expect(find.byType(QrImageView), findsOneWidget);
    // QrImageView paints via CustomPaint once data has been encoded successfully.
    expect(find.descendant(of: find.byType(QrImageView), matching: find.byType(CustomPaint)), findsWidgets);
  });

  testWidgets('QrImageView copes with an empty shareUrl (unconfigured/loading card) without crashing', (tester) async {
    // A plausible real-world trigger for "QR not working": if EmergencyCard.shareUrl is ever
    // empty (e.g. a card whose token generation failed server-side), does the widget crash
    // the screen instead of degrading gracefully?
    Object? caught;
    FlutterError.onError = (details) => caught = details.exception;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QrImageView(data: '', size: 220)),
      ),
    );
    await tester.pumpAndSettle();

    expect(caught, isNull, reason: 'An empty shareUrl should not throw an uncaught error while rendering the QR code');
  });
}
