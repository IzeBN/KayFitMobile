import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initApiClient();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        onboardingDoneProvider.overrideWith((ref) => onboardingDone),
      ],
      child: const _AppInit(),
    ),
  );
}

class _AppInit extends ConsumerStatefulWidget {
  const _AppInit();

  @override
  ConsumerState<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends ConsumerState<_AppInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) => const KayfitApp();
}
