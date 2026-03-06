import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final resp = await apiDio.get('/api/goals');
      final data = resp.data as Map<String, dynamic>;
      _caloriesCtrl.text = (data['calories'] as num).toInt().toString();
      _proteinCtrl.text = (data['protein'] as num).toInt().toString();
      _fatCtrl.text = (data['fat'] as num).toInt().toString();
      _carbsCtrl.text = (data['carbs'] as num).toInt().toString();
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
      await apiDio.post('/api/goals', data: {
        'calories': int.parse(_caloriesCtrl.text),
        'protein': int.parse(_proteinCtrl.text),
        'fat': int.parse(_fatCtrl.text),
        'carbs': int.parse(_carbsCtrl.text),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
        Navigator.of(context).pop();
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
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Цели КБЖУ')),
      body: _loading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MacroField(
                    controller: _caloriesCtrl,
                    label: 'Калории',
                    suffix: 'ккал',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _MacroField(
                    controller: _proteinCtrl,
                    label: 'Белки',
                    suffix: 'г',
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _MacroField(
                    controller: _fatCtrl,
                    label: 'Жиры',
                    suffix: 'г',
                    color: AppColors.warm,
                  ),
                  const SizedBox(height: 12),
                  _MacroField(
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

class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final Color color;

  const _MacroField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        suffixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Введите значение';
        final n = int.tryParse(v);
        if (n == null || n < 0) return 'Введите целое число';
        return null;
      },
    );
  }
}
