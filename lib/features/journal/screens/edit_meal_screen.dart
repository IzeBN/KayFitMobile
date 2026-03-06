import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать блюдо')),
      body: _loading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Название'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _caloriesCtrl,
                    label: 'Калории',
                    suffix: 'ккал',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _proteinCtrl,
                    label: 'Белки',
                    suffix: 'г',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _fatCtrl,
                    label: 'Жиры',
                    suffix: 'г',
                    color: AppColors.warm,
                  ),
                  const SizedBox(height: 12),
                  _DoubleField(
                    controller: _carbsCtrl,
                    label: 'Углеводы',
                    suffix: 'г',
                    color: AppColors.support,
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
                        : const Text('Сохранить'),
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

  const _DoubleField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.color,
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
        if (v == null || v.isEmpty) return 'Введите значение';
        final n = double.tryParse(v);
        if (n == null || n < 0) return 'Введите корректное число';
        return null;
      },
    );
  }
}
