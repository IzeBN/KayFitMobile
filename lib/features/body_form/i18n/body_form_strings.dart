/// Local i18n for the BodyForm feature.
///
/// We don't touch `lib/core/i18n/app_*.arb` (parallel work in another
/// session). When those files are unblocked, move strings into them and
/// delete this class.
abstract final class BodyFormStrings {
  static String currentQuestion(bool isRu) => isRu
      ? 'Какая у тебя сейчас форма тела?'
      : 'What is your current body shape?';

  static String desiredQuestion(bool isRu) =>
      isRu ? 'Какая форма тела — твоя цель?' : 'What body shape is your goal?';

  static String subtitle(bool isRu) =>
      isRu ? 'Двигай слайдер, чтобы выбрать форму' : 'Slide to pick the shape';

  static String nextButton(bool isRu) => isRu ? 'Далее' : 'Next';

  static String finishButton(bool isRu) => isRu ? 'Готово' : 'Done';

  static String sliderLean(bool isRu) => isRu ? 'Стройное' : 'Lean';

  static String sliderCurvy(bool isRu) => isRu ? 'Полное' : 'Curvy';

  static String goalLabel(bool isRu) => isRu ? 'Цель' : 'Goal';

  static String currentLabel(bool isRu) => isRu ? 'Текущая' : 'Current';

  static String settingsLabel(bool isRu) => isRu ? 'Форма тела' : 'Body Shape';

  // Goal info shown on step 1 (desired). Indices 0..6.
  static String goalTitle(int index, bool isRu) {
    if (index <= 2) return isRu ? 'Атлетическое' : 'Athletic';
    if (index == 3) return isRu ? 'Нормальное' : 'Normal';
    return isRu ? 'Рекомендуем консультацию' : 'Consultation recommended';
  }

  static String goalDesc(int index, bool isRu) {
    if (index <= 2) {
      return isRu
          ? 'Низкий процент жира, хорошо очерченные мышцы.'
          : 'Low body fat, well-defined muscles.';
    }
    if (index == 3) {
      return isRu
          ? 'Здоровый диапазон для большинства людей.'
          : 'Healthy range for most people.';
    }
    return isRu
        ? 'Рекомендуем проконсультироваться с врачом перед постановкой цели.'
        : 'We recommend consulting a doctor before setting this as your goal.';
  }

  static String goalRange(int index) => switch (index) {
    0 => '4%–6%',
    1 => '7%–10%',
    2 => '11%–15%',
    3 => '16%–23%',
    4 => '24%–30%',
    5 => '31%–40%',
    _ => '>40%',
  };

  static bool goalIsSafe(int index) => index <= 3;
}
