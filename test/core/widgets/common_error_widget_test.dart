import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';

void main() {
  testWidgets(
    'CommonErrorWidget shows "No Internet Connection" for SocketException',
    (WidgetTester tester) async {
      // Arrange
      const error = 'SocketException: Failed host lookup';
      bool retryCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommonErrorWidget(
            error: error,
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      // Assert
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.text('Please check your network settings and try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      // Act - Tap Retry
      await tester.tap(find.text('Retry'));
      expect(retryCalled, true);
    },
  );

  testWidgets(
    'CommonErrorWidget shows "Something went wrong" for generic error',
    (WidgetTester tester) async {
      // Arrange
      const error = 'Generic Error';
      bool retryCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CommonErrorWidget(
            error: error,
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.text('We encountered an error. Please try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Generic Error'), findsOneWidget);

      // Act - Tap Retry
      await tester.tap(find.text('Retry'));
      expect(retryCalled, true);
    },
  );
}
