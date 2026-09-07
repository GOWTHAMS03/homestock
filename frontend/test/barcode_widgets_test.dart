import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/barcode/widgets/manual_barcode_dialog.dart';

void main() {
  group('Barcode Widget Tests', () {
    testWidgets('ManualBarcodeDialog validates empty input', (WidgetTester tester) async {
      String? submittedBarcode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ManualBarcodeDialog.show(context, (code) {
                  submittedBarcode = code;
                }),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Enter Barcode Manually'), findsOneWidget);

      // Tap Lookup Product without entering barcode
      await tester.tap(find.text('Lookup Product'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a barcode number'), findsOneWidget);
      expect(submittedBarcode, isNull);
    });

    testWidgets('ManualBarcodeDialog accepts valid barcode input and submits', (WidgetTester tester) async {
      String? submittedBarcode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ManualBarcodeDialog.show(context, (code) {
                  submittedBarcode = code;
                }),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter valid EAN-13 barcode
      await tester.enterText(find.byType(TextFormField), '8901030000003');
      await tester.pumpAndSettle();

      // Tap Lookup Product
      await tester.tap(find.text('Lookup Product'));
      await tester.pumpAndSettle();

      // Dialog closed and callback invoked
      expect(find.text('Enter Barcode Manually'), findsNothing);
      expect(submittedBarcode, equals('8901030000003'));
    });

    testWidgets('ManualBarcodeDialog can be cancelled', (WidgetTester tester) async {
      String? submittedBarcode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ManualBarcodeDialog.show(context, (code) {
                  submittedBarcode = code;
                }),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should close without submitting
      expect(find.text('Enter Barcode Manually'), findsNothing);
      expect(submittedBarcode, isNull);
    });
  });
}
