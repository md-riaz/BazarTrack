import 'package:bazar/shared/widgets/receipt_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a receipt placeholder when no receipt exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReceiptImage(receiptUrl: null))),
    );

    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });

  testWidgets('renders an in-memory receipt image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptImage(
            receiptUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL1SAAAAABJRU5ErkJggg==',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ReceiptImage), findsOneWidget);
  });
}
