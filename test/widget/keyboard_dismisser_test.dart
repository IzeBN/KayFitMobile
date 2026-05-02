import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayfit/shared/widgets/keyboard_dismisser.dart';

void main() {
  group('KeyboardDismisser', () {
    testWidgets('renders its child', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: KeyboardDismisser(
            child: Scaffold(
              body: Text('hello'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('unfocuses on tap outside TextField', (tester) async {
      // Arrange
      final focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardDismisser(
            child: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: focusNode),
                  const SizedBox(height: 200, key: Key('outside')),
                ],
              ),
            ),
          ),
        ),
      );

      // Act: give focus to the TextField
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Act: tap outside the TextField (empty screen area below the field)
      await tester.tapAt(const Offset(200, 400));
      await tester.pump();

      // Assert: focus removed
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('wraps child in GestureDetector with opaque behavior',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: KeyboardDismisser(
            child: Scaffold(body: SizedBox()),
          ),
        ),
      );

      // Assert: GestureDetector is present
      final gesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byType(KeyboardDismisser),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(gesture.behavior, equals(HitTestBehavior.opaque));
    });
  });
}
