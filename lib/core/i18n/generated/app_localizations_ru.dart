// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Kayfit';

  @override
  String get nav_today => 'Сегодня';

  @override
  String get nav_journal => 'Журнал';

  @override
  String get nav_settings => 'Настройки';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_edit => 'Редактировать';

  @override
  String get common_loading => 'Загрузка...';

  @override
  String get common_error => 'Ошибка';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_next => 'Далее';

  @override
  String get common_back => 'Назад';

  @override
  String get common_done => 'Готово';

  @override
  String get common_skip => 'Пропустить';

  @override
  String get common_stop => 'Стоп';

  @override
  String get macro_calories => 'Калории';

  @override
  String get macro_protein => 'Белки';

  @override
  String get macro_fat => 'Жиры';

  @override
  String get macro_carbs => 'Углеводы';

  @override
  String get macro_kcal => 'ккал';

  @override
  String get macro_g => 'г';

  @override
  String get macro_eaten => 'съедено';

  @override
  String get macro_remaining => 'осталось';

  @override
  String get macro_goal => 'цель';

  @override
  String get dashboard_title => 'Сегодня';

  @override
  String get dashboard_addMeal => 'Добавить приём пищи';

  @override
  String get dashboard_noMeals => 'Нет записей за сегодня';

  @override
  String dashboard_compulsive(int count) {
    return 'Компульсивных приёмов: $count';
  }

  @override
  String get journal_title => 'Журнал';

  @override
  String get journal_empty => 'История пуста';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_profile => 'Профиль';

  @override
  String get settings_language => 'Язык';

  @override
  String get settings_subscription => 'Подписка';

  @override
  String get settings_logout => 'Выйти';

  @override
  String get settings_langRu => 'Русский';

  @override
  String get settings_langEn => 'English';

  @override
  String get settings_goals => 'Цели КБЖУ';

  @override
  String get addMeal_title => 'Добавить блюдо';

  @override
  String get addMeal_text => 'Текстом';

  @override
  String get addMeal_voice => 'Голосом';

  @override
  String get addMeal_photo => 'Фото';

  @override
  String get addMeal_manual => 'Вручную';

  @override
  String get addMeal_emotionTitle => 'Как вы себя чувствуете?';

  @override
  String get addMeal_inputHint => 'Опишите что съели...';

  @override
  String get addMeal_parsing => 'Распознаём...';

  @override
  String get addMeal_selectItems => 'Выберите блюда';

  @override
  String get addMeal_add => 'Добавить';

  @override
  String get addMeal_recording => 'Идёт запись...';

  @override
  String get addMeal_stopRecording => 'Остановить';

  @override
  String get addMeal_transcribing => 'Распознаём речь...';

  @override
  String get addMeal_takePhoto => 'Сделать фото';

  @override
  String get addMeal_choosePhoto => 'Выбрать из галереи';

  @override
  String get addMeal_recognizing => 'Распознаём...';

  @override
  String meal_calories(double cal) {
    final intl.NumberFormat calNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String calString = calNumberFormat.format(cal);

    return '$calString ккал';
  }

  @override
  String meal_macros(double p, double f, double c) {
    return 'Б: $pг  Ж: $fг  У: $cг';
  }

  @override
  String get emotion_happy => 'Радость';

  @override
  String get emotion_calm => 'Спокойствие';

  @override
  String get emotion_sad => 'Грусть';

  @override
  String get emotion_anxious => 'Тревога';

  @override
  String get emotion_tired => 'Усталость';

  @override
  String get emotion_hungry => 'Голод';

  @override
  String get emotion_bored => 'Скука';

  @override
  String get emotion_angry => 'Злость';

  @override
  String get emotion_worried => 'Беспокойство';

  @override
  String get emotion_neutral => 'Нейтральность';

  @override
  String get emotion_other => 'Другое';

  @override
  String get ob_landing_title1 => 'Худей';

  @override
  String get ob_landing_title2 => 'просто';

  @override
  String get ob_landing_sub =>
      'Сфотографируй или опиши голосом еду — AI посчитает калории';

  @override
  String get ob_landing_cta => 'Попробовать сейчас';

  @override
  String get ob_landing_cta_sub1 => 'Персональный план';

  @override
  String get ob_landing_cta_sub2 => 'меньше минуты';

  @override
  String get ob_skip_btn => 'Пропустить';

  @override
  String get ob_skip_title => 'Пропустить шаг?';

  @override
  String get ob_skip_sub => 'Без этих данных расчёт будет менее точным.';

  @override
  String get ob_skip_continue => 'Продолжить без данных';

  @override
  String get ob_skip_back => 'Вернуться';

  @override
  String get ob_step_age_title => 'Ваш возраст?';

  @override
  String get ob_step_age_hint =>
      'Возраст влияет на расчёт базового обмена веществ';

  @override
  String get ob_step_height_title => 'Ваш рост?';

  @override
  String get ob_step_height_hint =>
      'Рост помогает рассчитать базовый обмен веществ';

  @override
  String get ob_step_height_unit => 'сантиметры';

  @override
  String get ob_step_gender_title => 'Ваш пол?';

  @override
  String get ob_step_gender_hint => 'Пол учитывается в формуле Миффлина';

  @override
  String get ob_step_gender_female => 'Женщина';

  @override
  String get ob_step_gender_male => 'Мужчина';

  @override
  String get ob_step_weight_title => 'Ваш вес?';

  @override
  String get ob_step_weight_hint =>
      'Текущий и желаемый вес для расчёта дефицита калорий';

  @override
  String get ob_step_weight_now => 'Сейчас';

  @override
  String get ob_step_weight_goal => 'Цель';

  @override
  String get ob_step_training_title => 'Дни тренировок?';

  @override
  String get ob_step_training_sub =>
      'Это поможет точнее рассчитать суточную активность';

  @override
  String get ob_training_none => 'Не тренируюсь';

  @override
  String get ob_training_monday => 'Понедельник';

  @override
  String get ob_training_tuesday => 'Вторник';

  @override
  String get ob_training_wednesday => 'Среда';

  @override
  String get ob_training_thursday => 'Четверг';

  @override
  String get ob_training_friday => 'Пятница';

  @override
  String get ob_training_saturday => 'Суббота';

  @override
  String get ob_training_sunday => 'Воскресенье';

  @override
  String get ob_method_title => 'Как добавить еду?';

  @override
  String get ob_method_sub => 'Выбери удобный способ — AI распознает КБЖУ';

  @override
  String get ob_method_photo_title => 'Фото еды';

  @override
  String get ob_method_photo_desc =>
      'Сфотографируй блюдо — AI определит состав за 5 сек';

  @override
  String get ob_method_voice_title => 'Голосом';

  @override
  String get ob_method_voice_desc => '«Съел борщ 300 мл» — просто скажи';

  @override
  String get ob_method_text_title => 'Текстом';

  @override
  String get ob_method_text_desc => 'Напиши что съел — AI посчитает калории';

  @override
  String get ob_method_note => 'Все способы работают быстро и точно';

  @override
  String get ob_demo_perks_title => 'Что ты получишь в Kayfit:';

  @override
  String get ob_demo_perk1 => 'Фото еды → AI распознает КБЖУ';

  @override
  String get ob_demo_perk2 => 'Голосом: «Съел борщ» — и готово';

  @override
  String get ob_demo_perk3 => 'История питания и прогресс';

  @override
  String get ob_demo_perk4 => 'Рекомендации по питанию от ИИ';

  @override
  String get ob_result_title => 'Ваш персональный план';

  @override
  String get ob_result_sub => 'Расчёт на основе вашего профиля';

  @override
  String get ob_result_kcalday => 'ккал/день';

  @override
  String get ob_result_accuracy => 'Точность ≈ 94%';

  @override
  String get ob_result_next_title => 'Следующий шаг';

  @override
  String get ob_result_next_text =>
      'Войдите, чтобы сохранить план и начать отслеживать питание.';

  @override
  String get ob_err_height => 'Введите корректный рост (100–250 см)';

  @override
  String get ob_err_weight => 'Введите корректный вес (30–300 кг)';

  @override
  String get ob_err_training => 'Выберите хотя бы один вариант';

  @override
  String get ob_footer_saving => 'Сохранение...';

  @override
  String get ob_footer_calc => 'Рассчитать план';

  @override
  String get ob_footer_great => 'Отлично!';

  @override
  String get ob_footer_login => 'Войти и сохранить план';

  @override
  String get ob_continue => 'Продолжить';

  @override
  String get ob_getStarted => 'Начать';

  @override
  String get auth_title => 'Войти в Kayfit';

  @override
  String get auth_subtitle => 'Выберите способ входа';

  @override
  String get auth_google => 'Войти через Google';

  @override
  String get auth_apple => 'Войти через Apple';

  @override
  String get auth_telegram => 'Войти через Telegram';

  @override
  String get auth_email => 'Войти по email';

  @override
  String get auth_terms =>
      'Продолжая, вы соглашаетесь с условиями использования';

  @override
  String get tariffs_title => 'Тарифы';

  @override
  String get tariffs_subscribe => 'Оформить подписку';

  @override
  String get tariffs_current => 'Текущий тариф';

  @override
  String get tariffs_free => 'Бесплатно';

  @override
  String get tariffs_perMonth => '/ месяц';

  @override
  String get tariffs_cancel => 'Отменить автопродление';

  @override
  String get tariffs_cancelConfirm =>
      'Вы уверены, что хотите отменить автопродление?';

  @override
  String get wg_title => 'Рассчитаем ваш путь к цели';

  @override
  String get wg_sub => 'Введите данные для расчёта калорий и БЖУ';

  @override
  String get wg_age => 'Возраст (лет)';

  @override
  String get wg_weight => 'Текущий вес (кг)';

  @override
  String get wg_height => 'Рост (см)';

  @override
  String get wg_target_weight => 'Целевой вес (кг, опционально)';

  @override
  String get wg_deficit => 'Режим дефицита';

  @override
  String get wg_deficit_active => 'Активный (-600 ккал)';

  @override
  String get wg_deficit_gentle => 'Бережный (-300 ккал)';

  @override
  String get wg_btn_next => 'Далее';

  @override
  String get wg_btn_calculating => 'Расчёт...';

  @override
  String get wg_err_fill => 'Заполните возраст, вес и рост';

  @override
  String get wg_err_data => 'Проверьте корректность данных';

  @override
  String get wg_result_title => 'Ваш путь к цели';

  @override
  String get wg_result_reach => 'Вы достигнете цели';

  @override
  String get wg_result_target_weight => 'Целевой вес';

  @override
  String get wg_result_kg => 'кг';

  @override
  String get wg_result_bmr => 'BMR (базовый обмен):';

  @override
  String get wg_result_tdee => 'TDEE (суточный расход):';

  @override
  String get wg_result_days => 'Дней до цели:';

  @override
  String get wg_result_kcal_day => 'ккал/день';

  @override
  String get wg_btn_start => 'Начать отслеживать';

  @override
  String get error_network => 'Нет соединения с сервером';

  @override
  String get error_auth => 'Ошибка авторизации';

  @override
  String get error_unknown => 'Что-то пошло не так';

  @override
  String get subscription_title => 'Подписка';

  @override
  String get subscription_none => 'У вас нет активной подписки';

  @override
  String get subscription_view_tariffs => 'Посмотреть тарифы';

  @override
  String get subscription_active => 'Активная подписка';

  @override
  String get subscription_expires => 'Действует до';

  @override
  String get subscription_amount => 'Стоимость';

  @override
  String get subscription_auto_renew => 'Автопродление';

  @override
  String get subscription_auto_renew_on => 'Включено';

  @override
  String get subscription_auto_renew_off => 'Отключено';

  @override
  String get subscription_cancel_auto_renew => 'Отменить автопродление';

  @override
  String get subscription_cancel_auto_renew_title => 'Отмена автопродления';

  @override
  String get subscription_cancel_auto_renew_confirm =>
      'Вы уверены, что хотите отменить автопродление подписки?';

  @override
  String get subscription_cancel_auto_renew_action => 'Отменить';

  @override
  String get subscription_auto_renew_cancelled => 'Автопродление отменено';
}
