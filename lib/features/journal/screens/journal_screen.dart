import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../widgets/meal_item.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/meal.dart';
import '../../../core/api/api_client.dart';

part 'journal_screen.g.dart';

@riverpod
Future<List<Meal>> mealHistory(MealHistoryRef ref) async {
  final resp = await apiDio.get('/api/meals/history', queryParameters: {'limit': 100});
  final list = resp.data as List<dynamic>;
  return list.map((e) => Meal.fromJson(e as Map<String, dynamic>)).toList();
}

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(mealHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.journal_title)),
      body: history.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(l10n.journal_empty,
                  style: const TextStyle(color: AppColors.textMuted)),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => ref.invalidate(mealHistoryProvider),
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => MealItem(meal: list[i]),
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
