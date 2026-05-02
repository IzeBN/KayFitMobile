import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kayfit/core/ai_consent/ai_consent_provider.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:kayfit/features/chat/screens/chat_screen.dart';

/// Minimal fake notifier for AI consent — always returns true so that
/// ChatScreen doesn't block on a consent gate.
class _FakeAiConsentNotifier extends AiConsentNotifier {
  @override
  bool? build() => true;
}

/// Builds a testable app that hosts [ChatScreen] at '/chat' with all
/// required delegates (localizations, router).
Widget _buildTestApp() {
  final router = GoRouter(
    initialLocation: '/chat',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(
        path: '/chat',
        builder: (_, __) => const ChatScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      aiConsentProvider.overrideWith(() => _FakeAiConsentNotifier()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  // ChatScreen calls AnalyticsService (Firebase) on initState.
  // In unit tests Firebase is not initialized, so we suppress those errors.
  void Function(FlutterErrorDetails)? _savedHandler;

  setUp(() {
    _savedHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      // Swallow Firebase-related errors; let everything else through.
      final message = details.exception.toString();
      if (message.contains('Firebase') ||
          message.contains('firebase') ||
          message.contains('No Firebase App') ||
          message.contains('FirebaseException')) return;
      _savedHandler?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = _savedHandler;
  });

  group('ChatScreen — back button (ticket 7.3)', () {
    testWidgets('back button icon is visible in the chat header',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      // Pump a few frames so GoRouter settles on /chat and
      // the widget tree completes its first build.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Drain any pending exception from Firebase / network init.
      tester.takeException();

      // The back arrow icon introduced by Axis C must be present.
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets(
        'delete icon is absent when no messages have loaded (empty state)',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      tester.takeException();

      // The delete icon only appears when _messages.isNotEmpty —
      // no real HTTP in tests, so the list stays empty.
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });
}
