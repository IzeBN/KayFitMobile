import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kayfit/features/body_form/body_form_calc.dart';
import 'package:kayfit/features/body_form/i18n/body_form_strings.dart';
import 'package:kayfit/features/body_form/screens/body_form_screen.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ru')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

bool _isAssetWithSubstring(Widget w, String needle) {
  if (w is! Image) return false;
  final image = w.image;
  if (image is! AssetImage) return false;
  return image.assetName.contains(needle);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WT-01 step 0 shows the "current shape" question', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: false)),
    );
    await tester.pump();
    expect(find.text(BodyFormStrings.currentQuestion(false)), findsOneWidget);
    expect(find.text(BodyFormStrings.desiredQuestion(false)), findsNothing);
  });

  testWidgets('WT-02 the slider exposes 7 tappable dots', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: false)),
    );
    await tester.pump();
    for (var i = 0; i < 7; i++) {
      expect(
        find.byKey(ValueKey('body-form-dot-$i')),
        findsOneWidget,
        reason: 'missing dot $i',
      );
    }
  });

  testWidgets('WT-03 male gender renders male body assets', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: false)),
    );
    await tester.pump();
    final maleImage = find.byWidgetPredicate(
      (w) => _isAssetWithSubstring(w, 'body-form-1.jpg'),
    );
    expect(maleImage, findsOneWidget);
    final femaleImage = find.byWidgetPredicate(
      (w) => _isAssetWithSubstring(w, 'body-form-girl-'),
    );
    expect(femaleImage, findsNothing);
  });

  testWidgets('WT-04 female gender renders girl-* body assets', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'female', isOnboarding: false)),
    );
    await tester.pump();
    final femaleImage = find.byWidgetPredicate(
      (w) => _isAssetWithSubstring(w, 'body-form-girl-1.jpg'),
    );
    expect(femaleImage, findsOneWidget);
  });

  testWidgets('WT-05 tapping a dot swaps the displayed image', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: false)),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => _isAssetWithSubstring(w, 'body-form-1.jpg'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('body-form-dot-3')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => _isAssetWithSubstring(w, 'body-form-4.jpg'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('WT-06 "Next" advances to step 1 with goal card', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: false)),
    );
    await tester.pump();
    final nextBtn = find.text(BodyFormStrings.nextButton(false));
    await tester.ensureVisible(nextBtn);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    expect(find.text(BodyFormStrings.desiredQuestion(false)), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
  });

  testWidgets('WT-07 onCompleted fires with computed target weight', (
    tester,
  ) async {
    int? cb1;
    int? cb2;
    double? cb3;
    await tester.pumpWidget(
      _wrap(
        BodyFormScreen(
          gender: 'male',
          isOnboarding: false,
          initialCurrent: 4,
          initialDesired: 4,
          currentWeight: 80,
          onCompleted: (a, b, c) {
            cb1 = a;
            cb2 = b;
            cb3 = c;
          },
        ),
      ),
    );
    await tester.pump();
    final nextBtn = find.text(BodyFormStrings.nextButton(false));
    await tester.ensureVisible(nextBtn);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('body-form-dot-1')));
    await tester.pumpAndSettle();
    final doneBtn = find.text(BodyFormStrings.finishButton(false));
    await tester.ensureVisible(doneBtn);
    await tester.tap(doneBtn);
    await tester.pumpAndSettle();
    expect(cb1, 4);
    expect(cb2, 1);
    expect(
      cb3,
      closeTo(
        calcTargetWeight(currentWeight: 80, currentIndex: 4, desiredIndex: 1)!,
        0.01,
      ),
    );
  });

  testWidgets('WT-08 back from step 1 returns to step 0', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: false)),
    );
    await tester.pump();
    final nextBtn = find.text(BodyFormStrings.nextButton(false));
    await tester.ensureVisible(nextBtn);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    expect(find.text(BodyFormStrings.desiredQuestion(false)), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text(BodyFormStrings.currentQuestion(false)), findsOneWidget);
  });

  testWidgets('WT-09 isOnboarding=true hides the local header', (tester) async {
    await tester.pumpWidget(
      _wrap(BodyFormScreen(gender: 'male', isOnboarding: true)),
    );
    await tester.pump();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });
}
