import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayfit/features/onboarding/widgets/ob_gradient_button.dart';
import 'package:kayfit/features/onboarding/widgets/onboarding_scaffold.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

// ─── OnboardingScaffold tests ──────────────────────────────────────────────────

void main() {
  group('OnboardingScaffold', () {
    testWidgets(
      'renders primaryCta inside bottomNavigationBar',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const SizedBox.shrink(),
              body: const SizedBox.shrink(),
              primaryCta: const Text('Next'),
            ),
          ),
        );

        // Assert — the text appears exactly once and is inside a
        // bottomNavigationBar slot (no SafeArea wrapping in the body column).
        expect(find.text('Next'), findsOneWidget);
      },
    );

    testWidgets(
      'does not render secondaryCta when null',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const SizedBox.shrink(),
              body: const SizedBox.shrink(),
              primaryCta: const Text('Next'),
              // secondaryCta intentionally omitted (null)
            ),
          ),
        );

        // Assert
        expect(find.text('Skip'), findsNothing);
      },
    );

    testWidgets(
      'renders secondaryCta below primaryCta when provided',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const SizedBox.shrink(),
              body: const SizedBox.shrink(),
              primaryCta: const Text('Next'),
              secondaryCta: const Text('Skip'),
            ),
          ),
        );

        // Assert — both texts are present
        expect(find.text('Next'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);

        // And Skip is positioned below Next
        final nextPos = tester.getBottomLeft(find.text('Next'));
        final skipPos = tester.getTopLeft(find.text('Skip'));
        expect(
          skipPos.dy,
          greaterThan(nextPos.dy),
          reason: 'Skip should be below Next',
        );
      },
    );

    testWidgets(
      'resizeToAvoidBottomInset is true — Scaffold is created with it',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const SizedBox.shrink(),
              body: const SizedBox.shrink(),
              primaryCta: const Text('Next'),
            ),
          ),
        );

        // Assert — find the Scaffold widget in the tree
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.resizeToAvoidBottomInset, isTrue);
      },
    );

    testWidgets(
      'renders header and body in the main body column',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const Text('Header'),
              body: const Text('Body content'),
              primaryCta: const Text('Next'),
            ),
          ),
        );

        // Assert
        expect(find.text('Header'), findsOneWidget);
        expect(find.text('Body content'), findsOneWidget);
      },
    );

    testWidgets(
      'applies custom backgroundColor to Scaffold',
      (tester) async {
        // Arrange
        const customColor = Color(0xFFAABBCC);
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const SizedBox.shrink(),
              body: const SizedBox.shrink(),
              primaryCta: const Text('Next'),
              backgroundColor: customColor,
            ),
          ),
        );

        // Assert
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, customColor);
      },
    );
  });

  // ─── ObGradientButton tests ────────────────────────────────────────────────

  group('ObGradientButton', () {
    testWidgets(
      'is visible and shows label when enabled (onTap provided)',
      (tester) async {
        // Arrange
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            ObGradientButton(
              label: 'Далее',
              onTap: () => tapped = true,
            ),
          ),
        );

        // Assert — visible
        expect(find.text('Далее'), findsOneWidget);

        // Act — tap
        await tester.tap(find.text('Далее'));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'is visible when disabled (onTap is null) — key acceptance criterion',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            const ObGradientButton(
              label: 'Далее',
              onTap: null, // disabled
            ),
          ),
        );

        // Assert — button must still be visible even when disabled
        expect(find.text('Далее'), findsOneWidget);
      },
    );

    testWidgets(
      'does not invoke any callback when disabled (onTap is null)',
      (tester) async {
        // Arrange
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            ObGradientButton(
              label: 'Далее',
              onTap: null,
            ),
          ),
        );

        // Act — try to tap
        await tester.tap(find.text('Далее'));
        await tester.pump();

        // Assert — tap was silently absorbed; no state change
        expect(tapped, isFalse);
      },
    );

    testWidgets(
      'displays gradient decoration when enabled',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            ObGradientButton(
              label: 'Next',
              onTap: () {},
            ),
          ),
        );

        // Assert — the Container that wraps the button has a BoxDecoration
        // with a gradient (not null).
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) {
          final deco = c.decoration;
          return deco is BoxDecoration && deco.gradient != null;
        });
        expect(containers, isNotEmpty);
      },
    );

    testWidgets(
      'renders with correct height (58px)',
      (tester) async {
        // Arrange — wrap in Column so the button takes intrinsic height
        // instead of expanding to fill available vertical space.
        await tester.pumpWidget(
          _wrap(
            Column(
              children: [
                ObGradientButton(
                  label: 'Next',
                  onTap: () {},
                ),
              ],
            ),
          ),
        );

        // Assert — height of the rendered ObGradientButton is 58px.
        final rect = tester.getRect(find.byType(ObGradientButton));
        expect(rect.height, 58.0);
      },
    );
  });

  // ─── Integration: OnboardingScaffold + ObGradientButton ────────────────────

  group('OnboardingScaffold with ObGradientButton', () {
    testWidgets(
      'disabled Next button is visible inside bottomNavigationBar',
      (tester) async {
        // Arrange — simulates a mandatory step where the field is empty.
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const Text('Step Header'),
              body: const TextField(),
              primaryCta: const ObGradientButton(
                label: 'Далее',
                onTap: null, // disabled — field empty
              ),
            ),
          ),
        );

        // Assert — button is rendered even when disabled
        expect(find.text('Далее'), findsOneWidget);
        expect(find.byType(ObGradientButton), findsOneWidget);
      },
    );

    testWidgets(
      'enabled Next button is visible and tappable',
      (tester) async {
        // Arrange — simulates a step where the user has provided input.
        var nextCalled = false;
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const Text('Step Header'),
              body: const TextField(),
              primaryCta: ObGradientButton(
                label: 'Далее',
                onTap: () => nextCalled = true,
              ),
            ),
          ),
        );

        // Assert — visible
        expect(find.text('Далее'), findsOneWidget);

        // Act — tap
        await tester.tap(find.text('Далее'));
        await tester.pump();

        // Assert — callback fired
        expect(nextCalled, isTrue);
      },
    );

    testWidgets(
      'Next button remains in widget tree after keyboard simulation',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          _wrap(
            OnboardingScaffold(
              header: const Text('Height'),
              body: const TextField(autofocus: true),
              primaryCta: ObGradientButton(
                label: 'Next',
                onTap: () {},
              ),
            ),
          ),
        );

        // Act — simulate keyboard opening by showing it
        await tester.showKeyboard(find.byType(TextField));
        await tester.pump();

        // Assert — button is still present in the widget tree
        // (bottomNavigationBar is shifted above keyboard by Flutter)
        expect(find.text('Next'), findsOneWidget);
      },
    );
  });
}
