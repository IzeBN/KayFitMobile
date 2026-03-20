import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/analytics/analytics_service.dart';
import 'core/auth/auth_provider.dart';
import 'core/ai_consent/ai_consent_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/journal/screens/journal_screen.dart';
import 'features/journal/screens/edit_meal_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/goals_screen.dart';
import 'features/auth/screens/email_auth_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/way_to_goal/screens/way_to_goal_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/ai_consent/screens/ai_consent_screen.dart';
import 'shared/widgets/bottom_nav.dart';

const _kOnboardingDoneKey = 'onboarding_done';

// Tracks whether user has seen onboarding this session.
// Loaded once at startup from SharedPreferences.
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

/// Set to true after email auth when onboarding data was synced.
/// Router redirects to /way-to-goal once; WayToGoalScreen clears it.
final showWayToGoalProvider = StateProvider<bool>((ref) => false);

/// Call after successful onboarding completion to mark it done.
Future<void> markOnboardingDone(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
  ref.read(onboardingDoneProvider.notifier).state = true;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  final onboardingDone = ref.watch(onboardingDoneProvider);
  final showWayToGoal = ref.watch(showWayToGoalProvider);
  final aiConsent = ref.watch(aiConsentProvider);

  return GoRouter(
    initialLocation: '/',
    observers: [AnalyticsService.routeObserver],
    redirect: (context, state) {
      if (authNotifier.isLoading) return null;

      final isLoggedIn = authNotifier.value != null;
      final loc = state.matchedLocation;

      // Public routes
      final isPublic = loc == '/login' ||
          loc == '/email-auth' ||
          loc == '/onboarding' ||
          loc == '/way-to-goal' ||
          loc == '/ai-consent';

      if (!isLoggedIn) {
        if (isPublic) return null;
        // New user → onboarding first
        return onboardingDone ? '/login' : '/onboarding';
      }

      // Logged in
      if (loc == '/login' || loc == '/email-auth' || loc == '/onboarding') return '/';

      // If coming from onboarding+auth flow, redirect to /way-to-goal once
      if (showWayToGoal && loc != '/way-to-goal') {
        return '/way-to-goal';
      }

      // If consent was never given (null), redirect to consent screen
      // Skip if already on /ai-consent or /way-to-goal (let way-to-goal finish first)
      if (isLoggedIn && aiConsent == null && !showWayToGoal &&
          loc != '/ai-consent' && loc != '/way-to-goal') {
        return '/ai-consent';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/email-auth',
        builder: (context, state) => const EmailAuthScreen(),
      ),
      GoRoute(
        path: '/way-to-goal',
        builder: (context, state) => const WayToGoalScreen(),
      ),
      GoRoute(
        path: '/ai-consent',
        builder: (context, state) => const AiConsentScreen(),
      ),
      GoRoute(
        path: '/settings/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/meals/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EditMealScreen(mealId: id);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
