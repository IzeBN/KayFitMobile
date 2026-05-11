/// Local i18n for the Reward onboarding step.
///
/// Texts ported verbatim from FitKeep `app_localizations_*.dart`
/// (`onboardingRewardQuestion`, `onboardingReward1..4`).
abstract final class RewardStrings {
  static String question(bool isRu) => isRu
      ? 'Как ты собираешься себя наградить после достижения цели?'
      : 'How will you reward yourself after reaching your goal?';

  static String subtitle(bool isRu) =>
      isRu ? 'Выбери один вариант' : 'Choose one option';

  static String optionLabel(String key, bool isRu) {
    return switch (key) {
      'clothes' => isRu ? 'Новая одежда' : 'New clothes',
      'travel' => isRu ? 'Путешествие или отпуск' : 'Travel or vacation',
      'event' => isRu ? 'Особое событие или праздник' : 'A special event',
      'gift' => isRu ? 'Подарок себе' : 'A gift to yourself',
      _ => key,
    };
  }
}
