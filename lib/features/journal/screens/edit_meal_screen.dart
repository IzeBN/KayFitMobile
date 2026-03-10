import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';

class EditMealScreen extends StatefulWidget {
  final int mealId;
  const EditMealScreen({super.key, required this.mealId});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    try {
      // Load from today's meals list and find the one with matching id
      final resp = await apiDio.get('/api/meals');
      final list = resp.data as List<dynamic>;
      final meal = list
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['id'] == widget.mealId);
      _nameCtrl.text = meal['name'] as String? ?? '';
      _caloriesCtrl.text = (meal['calories'] as num).toStringAsFixed(1);
      _proteinCtrl.text = (meal['protein'] as num).toStringAsFixed(1);
      _fatCtrl.text = (meal['fat'] as num).toStringAsFixed(1);
      _carbsCtrl.text = (meal['carbs'] as num).toStringAsFixed(1);
    } catch (_) {
      // leave fields empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await apiDio.patch('/api/meals/${widget.mealId}', data: {
        'name': _nameCtrl.text.trim(),
        'calories': double.parse(_caloriesCtrl.text),
        'protein': double.parse(_proteinCtrl.text),
        'fat': double.parse(_fatCtrl.text),
        'carbs': double.parse(_carbsCtrl.text),
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.edit_meal_saved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.edit_meal_error(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.edit_meal_title)),
      body: _loading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(labelText: l10n.edit_meal_name_label),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.edit_meal_name_error : null,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _caloriesCtrl,
                    label: l10n.macro_calories,
                    suffix: l10n.macro_kcal,
                    color: AppColors.accent,
                    errEnterValue: l10n.edit_meal_err_enter_value,
                    errInvalidNumber: l10n.edit_meal_err_invalid_number,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _proteinCtrl,
                    label: l10n.macro_protein,
                    suffix: l10n.macro_g,
                    color: AppColors.accent,
                    errEnterValue: l10n.edit_meal_err_enter_value,
                    errInvalidNumber: l10n.edit_meal_err_invalid_number,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _fatCtrl,
                    label: l10n.macro_fat,
                    suffix: l10n.macro_g,
                    color: AppColors.warm,
                    errEnterValue: l10n.edit_meal_err_enter_value,
                    errInvalidNumber: l10n.edit_meal_err_invalid_number,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _carbsCtrl,
                    label: l10n.macro_carbs,
                    suffix: l10n.macro_g,
                    color: AppColors.support,
                    errEnterValue: l10n.edit_meal_err_enter_value,
                    errInvalidNumber: l10n.edit_meal_err_invalid_number,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.common_save),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DoubleField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final Color color;
  final String errEnterValue;
  final String errInvalidNumber;

  const _DoubleField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.color,
    required this.errEnterValue,
    required this.errInvalidNumber,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        suffixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return errEnterValue;
        final n = double.tryParse(v);
        if (n == null || n < 0) return errInvalidNumber;
        return null;
      },
    );
  }
}
