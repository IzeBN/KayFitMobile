// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kayfit';

  @override
  String get nav_today => 'Today';

  @override
  String get nav_journal => 'Journal';

  @override
  String get nav_settings => 'Settings';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'Error';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_next => 'Next';

  @override
  String get common_back => 'Back';

  @override
  String get common_done => 'Done';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_stop => 'Stop';

  @override
  String get macro_calories => 'Calories';

  @override
  String get macro_protein => 'Protein';

  @override
  String get macro_fat => 'Fat';

  @override
  String get macro_carbs => 'Carbs';

  @override
  String get macro_kcal => 'kcal';

  @override
  String get macro_g => 'g';

  @override
  String get macro_eaten => 'eaten';

  @override
  String get macro_remaining => 'remaining';

  @override
  String get macro_goal => 'goal';

  @override
  String get dashboard_title => 'Today';

  @override
  String get dashboard_addMeal => 'Add meal';

  @override
  String get dashboard_noMeals => 'No entries for today';

  @override
  String dashboard_compulsive(int count) {
    return 'Compulsive meals: $count';
  }

  @override
  String get journal_title => 'Journal';

  @override
  String get journal_empty => 'History is empty';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_profile => 'Profile';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_subscription => 'Subscription';

  @override
  String get settings_logout => 'Log out';

  @override
  String get settings_langRu => 'Russian';

  @override
  String get settings_langEn => 'English';

  @override
  String get settings_goals => 'Macro goals';

  @override
  String get addMeal_title => 'Add meal';

  @override
  String get addMeal_text => 'Text';

  @override
  String get addMeal_voice => 'Voice';

  @override
  String get addMeal_photo => 'Photo';

  @override
  String get addMeal_manual => 'Manual';

  @override
  String get addMeal_emotionTitle => 'How do you feel?';

  @override
  String get addMeal_inputHint => 'Describe what you ate...';

  @override
  String get addMeal_parsing => 'Recognizing...';

  @override
  String get addMeal_selectItems => 'Select items';

  @override
  String get addMeal_add => 'Add';

  @override
  String get addMeal_recording => 'Recording...';

  @override
  String get addMeal_stopRecording => 'Stop';

  @override
  String get addMeal_transcribing => 'Transcribing...';

  @override
  String get addMeal_takePhoto => 'Take photo';

  @override
  String get addMeal_choosePhoto => 'Choose from gallery';

  @override
  String get addMeal_recognizing => 'Recognizing...';

  @override
  String meal_calories(double cal) {
    final intl.NumberFormat calNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String calString = calNumberFormat.format(cal);

    return '$calString kcal';
  }

  @override
  String meal_macros(double p, double f, double c) {
    return 'P: ${p}g  F: ${f}g  C: ${c}g';
  }

  @override
  String get emotion_happy => 'Happy';

  @override
  String get emotion_calm => 'Calm';

  @override
  String get emotion_sad => 'Sad';

  @override
  String get emotion_anxious => 'Anxious';

  @override
  String get emotion_tired => 'Tired';

  @override
  String get emotion_hungry => 'Hungry';

  @override
  String get emotion_bored => 'Bored';

  @override
  String get emotion_angry => 'Angry';

  @override
  String get emotion_worried => 'Worried';

  @override
  String get emotion_neutral => 'Neutral';

  @override
  String get emotion_other => 'Other';

  @override
  String get ob_landing_title1 => 'Lose weight';

  @override
  String get ob_landing_title2 => 'easily';

  @override
  String get ob_landing_sub => 'Photo or voice — AI counts your calories';

  @override
  String get ob_landing_cta => 'Try now';

  @override
  String get ob_landing_cta_sub1 => 'Personal plan';

  @override
  String get ob_landing_cta_sub2 => 'in under a minute';

  @override
  String get ob_skip_btn => 'Skip';

  @override
  String get ob_skip_title => 'Skip this step?';

  @override
  String get ob_skip_sub =>
      'Without this data the calculation will be less precise.';

  @override
  String get ob_skip_continue => 'Continue without data';

  @override
  String get ob_skip_back => 'Go back';

  @override
  String get ob_step_age_title => 'Your age?';

  @override
  String get ob_step_age_hint =>
      'Age affects your basal metabolic rate calculation';

  @override
  String get ob_step_height_title => 'Your height?';

  @override
  String get ob_step_height_hint =>
      'Height helps calculate your basal metabolic rate';

  @override
  String get ob_step_height_unit => 'centimeters';

  @override
  String get ob_step_gender_title => 'Your gender?';

  @override
  String get ob_step_gender_hint => 'Used in the Mifflin calorie formula';

  @override
  String get ob_step_gender_female => 'Female';

  @override
  String get ob_step_gender_male => 'Male';

  @override
  String get ob_step_weight_title => 'Your weight?';

  @override
  String get ob_step_weight_hint =>
      'Current and target weight for calorie deficit calculation';

  @override
  String get ob_step_weight_now => 'Current';

  @override
  String get ob_step_weight_goal => 'Goal';

  @override
  String get ob_step_training_title => 'Training days?';

  @override
  String get ob_step_training_sub =>
      'This helps calculate your daily activity more precisely';

  @override
  String get ob_training_none => 'I don\'t train';

  @override
  String get ob_training_monday => 'Monday';

  @override
  String get ob_training_tuesday => 'Tuesday';

  @override
  String get ob_training_wednesday => 'Wednesday';

  @override
  String get ob_training_thursday => 'Thursday';

  @override
  String get ob_training_friday => 'Friday';

  @override
  String get ob_training_saturday => 'Saturday';

  @override
  String get ob_training_sunday => 'Sunday';

  @override
  String get ob_method_title => 'How to add food?';

  @override
  String get ob_method_sub =>
      'Choose your preferred way — AI recognizes macros';

  @override
  String get ob_method_photo_title => 'Food photo';

  @override
  String get ob_method_photo_desc =>
      'Snap a photo — AI identifies nutrients in 5 sec';

  @override
  String get ob_method_voice_title => 'Voice';

  @override
  String get ob_method_voice_desc => 'Say \'I ate soup 300ml\' — done';

  @override
  String get ob_method_text_title => 'Text';

  @override
  String get ob_method_text_desc =>
      'Write what you ate — AI calculates calories';

  @override
  String get ob_method_note => 'All methods work fast and accurately';

  @override
  String get ob_demo_perks_title => 'What you get with Kayfit:';

  @override
  String get ob_demo_perk1 => 'Food photo → AI recognizes macros';

  @override
  String get ob_demo_perk2 => 'Voice: \'Ate soup\' — that\'s it';

  @override
  String get ob_demo_perk3 => 'Nutrition history and progress';

  @override
  String get ob_demo_perk4 => 'AI nutrition recommendations';

  @override
  String get ob_result_title => 'Your personal plan';

  @override
  String get ob_result_sub => 'Calculated based on your profile';

  @override
  String get ob_result_kcalday => 'kcal/day';

  @override
  String get ob_result_accuracy => 'Accuracy ≈ 94%';

  @override
  String get ob_result_next_title => 'Next step';

  @override
  String get ob_result_next_text =>
      'Sign in to save your plan and start tracking nutrition.';

  @override
  String get ob_err_height => 'Enter a valid height (100–250 cm)';

  @override
  String get ob_err_weight => 'Enter a valid weight (30–300 kg)';

  @override
  String get ob_err_training => 'Select at least one option';

  @override
  String get ob_footer_saving => 'Saving...';

  @override
  String get ob_footer_calc => 'Calculate plan';

  @override
  String get ob_footer_great => 'Great!';

  @override
  String get ob_footer_login => 'Sign in and save plan';

  @override
  String get ob_continue => 'Continue';

  @override
  String get ob_getStarted => 'Get started';

  @override
  String get auth_title => 'Sign in to Kayfit';

  @override
  String get auth_subtitle => 'Choose a sign-in method';

  @override
  String get auth_google => 'Sign in with Google';

  @override
  String get auth_apple => 'Sign in with Apple';

  @override
  String get auth_telegram => 'Sign in with Telegram';

  @override
  String get auth_email => 'Sign in with Email';

  @override
  String get auth_terms => 'By continuing you agree to the terms of service';

  @override
  String get tariffs_title => 'Plans';

  @override
  String get tariffs_subscribe => 'Subscribe';

  @override
  String get tariffs_current => 'Current plan';

  @override
  String get tariffs_free => 'Free';

  @override
  String get tariffs_perMonth => '/ month';

  @override
  String get tariffs_cancel => 'Cancel auto-renewal';

  @override
  String get tariffs_cancelConfirm =>
      'Are you sure you want to cancel auto-renewal?';

  @override
  String get wg_title => 'Calculate your path to goal';

  @override
  String get wg_sub => 'Enter your data to calculate calories and macros';

  @override
  String get wg_age => 'Age (years)';

  @override
  String get wg_weight => 'Current weight (kg)';

  @override
  String get wg_height => 'Height (cm)';

  @override
  String get wg_target_weight => 'Target weight (kg, optional)';

  @override
  String get wg_deficit => 'Deficit mode';

  @override
  String get wg_deficit_active => 'Active (-600 kcal)';

  @override
  String get wg_deficit_gentle => 'Gentle (-300 kcal)';

  @override
  String get wg_btn_next => 'Next';

  @override
  String get wg_btn_calculating => 'Calculating...';

  @override
  String get wg_err_fill => 'Fill in age, weight and height';

  @override
  String get wg_err_data => 'Check your data for correctness';

  @override
  String get wg_result_title => 'Your path to goal';

  @override
  String get wg_result_reach => 'You will reach your goal by';

  @override
  String get wg_result_target_weight => 'Target weight';

  @override
  String get wg_result_kg => 'kg';

  @override
  String get wg_result_bmr => 'BMR (basal metabolic rate):';

  @override
  String get wg_result_tdee => 'TDEE (total daily energy expenditure):';

  @override
  String get wg_result_days => 'Days to goal:';

  @override
  String get wg_result_kcal_day => 'kcal/day';

  @override
  String get wg_btn_start => 'Start tracking';

  @override
  String get error_network => 'No server connection';

  @override
  String get error_auth => 'Authentication error';

  @override
  String get error_unknown => 'Something went wrong';

  @override
  String get subscription_title => 'Subscription';

  @override
  String get subscription_none => 'You have no active subscription';

  @override
  String get subscription_view_tariffs => 'View plans';

  @override
  String get subscription_active => 'Active subscription';

  @override
  String get subscription_expires => 'Valid until';

  @override
  String get subscription_amount => 'Amount';

  @override
  String get subscription_auto_renew => 'Auto-renewal';

  @override
  String get subscription_auto_renew_on => 'Enabled';

  @override
  String get subscription_auto_renew_off => 'Disabled';

  @override
  String get subscription_cancel_auto_renew => 'Cancel auto-renewal';

  @override
  String get subscription_cancel_auto_renew_title => 'Cancel auto-renewal';

  @override
  String get subscription_cancel_auto_renew_confirm =>
      'Are you sure you want to cancel subscription auto-renewal?';

  @override
  String get subscription_cancel_auto_renew_action => 'Cancel';

  @override
  String get subscription_auto_renew_cancelled => 'Auto-renewal cancelled';
}
