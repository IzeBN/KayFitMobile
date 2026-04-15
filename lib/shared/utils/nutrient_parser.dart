import 'dart:math' show max;
import '../models/ingredient.dart';
import '../models/ingredient_v2.dart';

/// Unified mapping from raw API JSON → [Ingredient].
///
/// Handles both response shapes:
/// - `*_per_100g` fields (values are per 100 g, scaled by weight)
/// - bare field names (values already scaled to the portion)
///
/// Falls back to heuristic estimates only when the API omits a field entirely.
Ingredient ingredientFromJson(Map<String, dynamic> raw) {
  // Unwrap nested `suggestions` array (some endpoints wrap data this way)
  final suggs = raw['suggestions'] as List<dynamic>?;
  final e = (suggs != null && suggs.isNotEmpty)
      ? Map<String, dynamic>.from(suggs[0] as Map)
      : raw;

  // Prefer the unwrapped item `e` for weight — `raw` is the envelope and may
  // carry an unrelated weight field.
  final w = _num(e, 'weight_grams') ?? _num(raw, 'weight_grams') ?? 100.0;

  // Scale factor: applied per-field to avoid double-scaling when the API
  // mixes `*_per_100g` and bare values in the same response.
  final wk = w / 100.0;

  // Core macros
  final cal = _scaled(e, 'calories', wk);
  final pro = _scaled(e, 'protein', wk);
  final fat = _scaled(e, 'fat', wk);
  final carb = _scaled(e, 'carbs', wk);

  // Extended nutrients — read real values, estimate only as last resort
  final rawFiber = _scaledOrNull(e, 'fiber', wk);
  final rawSugar = _scaledOrNull(e, 'sugar', wk);
  final rawSugarAlcohols = _scaledOrNull(e, 'sugar_alcohols', wk);
  final rawSatFat = _scaledOrNull(e, 'saturated_fat', wk);
  final rawUnsatFat = _scaledOrNull(e, 'unsaturated_fat', wk);

  // Apply heuristic fallbacks only when API returned nothing
  final actualFiber = rawFiber ?? carb * 0.03;
  final actualSugar = rawSugar ?? 0.0;
  final actualSugarAlcohols = rawSugarAlcohols ?? 0.0;
  final actualSatFat = rawSatFat ?? fat * 0.35;
  final actualUnsatFat = rawUnsatFat ?? fat * 0.65;

  final netCarbs = max(0.0, carb - actualFiber - actualSugarAlcohols);

  // Prefer `e` (unwrapped ingredient) for name over `raw` (envelope).
  return Ingredient(
    name: e['name'] as String? ?? raw['name'] as String? ?? '',
    weightGrams: w,
    calories: cal,
    protein: pro,
    fat: fat,
    carbs: carb,
    fiber: actualFiber,
    sugar: actualSugar,
    sugarAlcohols: actualSugarAlcohols,
    netCarbs: netCarbs,
    glycemicIndex: (e['glycemic_index'] as num?)?.toInt(),
    saturatedFat: actualSatFat,
    unsaturatedFat: actualUnsatFat,
  );
}

// ── V2 helpers ───────────────────────────────────────────────────────────────

/// Parse a v2 API item (with nested `nutrients_per_100g` + `nutrients_total`)
/// into an [IngredientV2].
IngredientV2 ingredientV2FromJson(Map<String, dynamic> raw) =>
    IngredientV2.fromApiItem(raw);

/// Parse a v2 suggestion item (only `nutrients_per_100g`) into an
/// [IngredientV2], scaling totals from [weightGrams].
IngredientV2 ingredientV2FromSuggestion(
        Map<String, dynamic> raw, double weightGrams) =>
    IngredientV2.fromSuggestion(raw, weightGrams);

// ── V1 Helpers ───────────────────────────────────────────────────────────────

double? _num(Map<String, dynamic> m, String key) =>
    (m[key] as num?)?.toDouble();

/// Returns the scaled value for [field].
///
/// If a `*_per_100g` key exists, uses it × [wk] (weight/100).
/// Otherwise returns the bare value as-is (already portion-scaled).
/// Missing fields default to `0.0`.
double _scaled(Map<String, dynamic> m, String field, double wk) {
  final per100 = (m['${field}_per_100g'] as num?)?.toDouble();
  if (per100 != null) return per100 * wk;
  return (m[field] as num?)?.toDouble() ?? 0.0;
}

/// Like [_scaled] but returns `null` when neither key exists, so the caller
/// can distinguish "API said 0" from "API didn't return this field at all".
double? _scaledOrNull(Map<String, dynamic> m, String field, double wk) {
  final per100 = (m['${field}_per_100g'] as num?)?.toDouble();
  if (per100 != null) return per100 * wk;
  return (m[field] as num?)?.toDouble();
}
