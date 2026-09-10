import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/widgets/app_button.dart';
import 'package:homestock/core/widgets/stock_status_badge.dart';
import 'package:homestock/core/widgets/quantity_stepper.dart';

void main() {
  testWidgets('AppButton renders label and responds to tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Add Item',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Add Item'), findsOneWidget);
    await tester.tap(find.text('Add Item'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('StockStatusBadge displays correct text and colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StockStatusBadge(status: StockStatusType.inStock),
              StockStatusBadge(status: StockStatusType.lowStock),
              StockStatusBadge(status: StockStatusType.outOfStock),
            ],
          ),
        ),
      ),
    );

    expect(find.text('In stock'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('QuantityStepper increments and decrements quantity', (WidgetTester tester) async {
    double qty = 5.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return QuantityStepper(
                value: qty,
                unit: 'kg',
                onIncrement: () => setState(() => qty += 1.0),
                onDecrement: () => setState(() => qty -= 1.0),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('5 kg'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(qty, equals(6.0));
  });
}
