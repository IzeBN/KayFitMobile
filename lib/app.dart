import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'core/locale/locale_provider.dart';
import 'core/notifications/notification_service.dart';
import 'router.dart';
import 'shared/theme/app_theme.dart';

class KayfitApp extends ConsumerWidget {
  const KayfitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // Register navigation callback for push notification taps.
    // Called every rebuild but GoRouter.go is idempotent when already on route.
    NotificationService.setNavigationCallback(router.go);

    return MaterialApp.router(
      title: 'Kayfit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
    );
  }
}
