import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/nutrient_parser.dart';
import '../../../shared/widgets/keyboard_dismisser.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _VariantGroup {
  final String food;
  final List<Map<String, dynamic>> variants;
  int selectedIndex = 0;

  _VariantGroup({
    required this.food,
    required this.variants,
  });
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// A bottom-sheet that lets the user search for and add ingredient(s).
///
/// Calls `POST /api/v2/parse_meal_variants`, displays variant groups,
/// and returns a `List<IngredientV2>` via [Navigator.pop].
///
/// Used by both [RecognitionResultSheetV2] and [RecognitionResultSheetKF2].
class IngredientSearchSheet extends StatefulWidget {
  const IngredientSearchSheet({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<IngredientSearchSheet> createState() => _IngredientSearchSheetState();
}

class _IngredientSearchSheetState extends State<IngredientSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  List<_VariantGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) _ctrl.text = widget.initialQuery!;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _focus.unfocus();
    setState(() {
      _loading = true;
      _groups = [];
    });
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final resp = await apiDio.post(
        '/api/v2/parse_meal_variants',
        data: {'text': text, 'language': lang},
      );
      final rawGroups = (resp.data['groups'] as List<dynamic>?) ?? [];
      final groups = rawGroups.map((g) {
        final variants = ((g['variants'] as List<dynamic>?) ?? [])
            .map((v) => v as Map<String, dynamic>)
            .toList();
        return _VariantGroup(
          food: g['food'] as String? ?? '',
          variants: variants,
        );
      }).where((g) => g.variants.isNotEmpty).toList();
      if (mounted) setState(() => _groups = groups);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addSelected() {
    if (_groups.isEmpty) return;
    HapticFeedback.mediumImpact();
    final items = _groups.map((g) {
      final raw = g.variants[g.selectedIndex];
      final w = (raw['weight_grams'] as num?)?.toDouble() ?? 100.0;
      return ingredientV2FromSuggestion(raw, w);
    }).toList();
    Navigator.pop(context, items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;

    return KeyboardDismisser(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: keyboardPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: NutrientColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.recogV2_search_ingredient,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NutrientColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: l10n.recogV2_search_hint,
                        filled: true,
                        fillColor: NutrientColors.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: NutrientColors.netCarbs,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search_rounded,
                              color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Variant groups
            if (_groups.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _groups.length,
                  itemBuilder: (_, gi) {
                    final group = _groups[gi];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.food,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...group.variants.asMap().entries.map((entry) {
                            final vi = entry.key;
                            final v = entry.value;
                            final isSelected = group.selectedIndex == vi;
                            final name = v['name'] as String? ?? '';
                            final per100 =
                                v['nutrients_per_100g']
                                        as Map<String, dynamic>? ??
                                    {};
                            final cal =
                                (per100['calories'] as num?)?.toDouble() ??
                                    0;
                            final w =
                                (v['weight_grams'] as num?)?.toDouble() ??
                                    100;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => group.selectedIndex = vi),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? NutrientColors.netCarbsSoft
                                      : NutrientColors.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? NutrientColors.netCarbs
                                        : NutrientColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? NutrientColors.netCarbs
                                                  : AppColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${cal.toStringAsFixed(0)} ${l10n.macro_kcal}/100${l10n.macro_g}  ·  '
                                            '${w.toStringAsFixed(0)}${l10n.macro_g}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: NutrientColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          color: NutrientColors.netCarbs,
                                          size: 18),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Add button
            if (_groups.isNotEmpty)
              Padding(
                padding:
                    EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addSelected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NutrientColors.netCarbs,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isRu ? 'Добавить выбранные' : 'Add selected',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            if (_groups.isEmpty && !_loading)
              SizedBox(height: bottomPad + 16),
          ],
        ),
      ),
    );
  }
}
