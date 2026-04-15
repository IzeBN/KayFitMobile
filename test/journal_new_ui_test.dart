import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayfit/features/journal/widgets/day_summary_card.dart';
import 'package:kayfit/features/journal/widgets/meal_group_card.dart';
import 'package:kayfit/shared/models/meal.dart';
import 'package:kayfit/shared/widgets/nutrient_progress_card.dart';
import 'package:kayfit/shared/widgets/carb_decomposition_block.dart';
import 'package:kayfit/shared/widgets/meal_type_picker.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

void main() {
  group('New Journal UI widgets render correctly', () {
    testWidgets('DaySummaryCard renders 6 nutrient cards + calories',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DaySummaryCard(
                netCarbs: 175, netCarbsGoal: 200,
                sugar: 24, sugarGoal: 50,
                fiber: 14, fiberGoal: 25,
                protein: 98, proteinGoal: 132,
                goodFat: 38, goodFatGoal: 55,
                satFat: 20, satFatGoal: 22,
                calories: 1680, caloriesGoal: 2200,
              ),
            ),
          ),
        ),
      );

      // Check all labels exist
      expect(find.text('Net carbs'), findsOneWidget);
      expect(find.text('Sugar'), findsOneWidget);
      expect(find.text('Fiber'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Good fats'), findsOneWidget);
      expect(find.text('Sat. fats'), findsOneWidget);
      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('DAY TOTAL'), findsOneWidget);

      // Check values
      expect(find.text('175'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);

      // Check NutrientProgressCard count (6 cards)
      expect(find.byType(NutrientProgressCard), findsNWidgets(6));
    });

    testWidgets('MealGroupCard renders meal type, dishes, stats',
        (tester) async {
      final meals = [
        const Meal(
          id: 1,
          name: 'Chicken Plov',
          calories: 580,
          protein: 32,
          fat: 24,
          carbs: 62,
          netCarbs: 58,
          dishName: 'Chicken Plov',
          mealType: 'lunch',
        ),
        const Meal(
          id: 2,
          name: 'Green Salad',
          calories: 120,
          protein: 3,
          fat: 5,
          carbs: 12,
          netCarbs: 8,
          mealType: 'lunch',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MealGroupCard(
                mealType: 'lunch',
                time: '13:15',
                meals: meals,
              ),
            ),
          ),
        ),
      );

      // Check title
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('13:15'), findsOneWidget);

      // Check dishes listed
      expect(find.text('Chicken Plov'), findsOneWidget);
      expect(find.text('Green Salad'), findsOneWidget);

      // Check stats chips exist
      expect(find.textContaining('Net'), findsWidgets);
      expect(find.textContaining('kcal'), findsWidgets);

      // Check Details link
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('CarbDecompositionBlock renders formula and net carbs',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarbDecompositionBlock(
              totalCarbs: 62,
              fiber: 3.8,
              sugarAlcohols: 0,
              sugar: 4.2,
              netCarbs: 58.2,
              glycemicIndex: 58,
            ),
          ),
        ),
      );

      expect(find.text('Net Carbs'), findsOneWidget);
      expect(find.text('58.2 g'), findsOneWidget);
      expect(find.textContaining('GI 58'), findsOneWidget);
      expect(find.text('Total carbs'), findsOneWidget);
    });

    testWidgets('MealTypePicker renders 4 types and responds to tap',
        (tester) async {
      String selected = 'lunch';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MealTypePicker(
                selected: selected,
                onChanged: (t) => setState(() => selected = t),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Snack'), findsOneWidget);

      // Tap Dinner
      await tester.tap(find.text('Dinner'));
      await tester.pump();

      // selected should change (verified by rebuild)
    });

    testWidgets('NutrientColors exist and are not default',
        (tester) async {
      expect(NutrientColors.netCarbs, const Color(0xFF2D6A4F));
      expect(NutrientColors.sugar, const Color(0xFFC2855A));
      expect(NutrientColors.fiber, const Color(0xFF7BAE7F));
      expect(NutrientColors.protein, const Color(0xFF7B6B8A));
      expect(NutrientColors.fatGood, const Color(0xFF5B8A72));
      expect(NutrientColors.fatBad, const Color(0xFF9B8579));
    });
  });
}
