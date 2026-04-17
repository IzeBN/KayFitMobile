import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/nutrients_v2.dart';
import '../theme/app_theme.dart';

/// Bottom sheet с полным списком нутриентов одного ингредиента/приёма пищи.
///
/// Использование:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => NutrientDetailSheet(
///     name: item.name,
///     weightGrams: item.weightGrams,
///     per100g: item.nutrientsPer100g,
///     total: item.nutrientsTotal,
///     source: item.source,
///     sourceUrl: item.sourceUrl,
///   ),
/// );
/// ```
class NutrientDetailSheet extends StatelessWidget {
  final String name;
  final double weightGrams;
  final NutrientsV2 per100g;
  final NutrientsV2 total;

  /// Источник данных: 'usda', 'fatsecret', 'claude', 'cache' или произвольный.
  final String source;
  final String? sourceUrl;

  const NutrientDetailSheet({
    super.key,
    required this.name,
    required this.weightGrams,
    required this.per100g,
    required this.total,
    required this.source,
    this.sourceUrl,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header: название + вес
            _NdsHeader(name: name, weightGrams: weightGrams),

            // Source badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SourceBadge(source: source, sourceUrl: sourceUrl),
              ),
            ),

            const SizedBox(height: 8),

            // Таблица нутриентов
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _NdsSection('Основные', [
                    _NdsRow.required('Калории', total.calories, 'ккал',
                        per100g.calories),
                    _NdsRow.required(
                        'Белки', total.protein, 'г', per100g.protein),
                    _NdsRow.required('Жиры', total.fat, 'г', per100g.fat),
                    _NdsRow.required(
                        'Углеводы', total.carbs, 'г', per100g.carbs),
                  ]),
                  _NdsSection('Углеводы детально', [
                    _NdsRow.optional(
                        'Клетчатка', total.fiber, 'г', per100g.fiber),
                    _NdsRow.optional('Сахарные спирты', total.sugarAlcohols,
                        'г', per100g.sugarAlcohols),
                    _NdsRow.optional(
                        'Чистые углеводы', total.netCarbs, 'г', per100g.netCarbs),
                    _NdsRow.gi(per100g.glycemicIndex,
                        per100g.glycemicIndexCategory),
                  ]),
                  _NdsSection('Жиры детально', [
                    _NdsRow.optional('Насыщенные', total.saturatedFat, 'г',
                        per100g.saturatedFat),
                    _NdsRow.optional('Мононенасыщенные',
                        total.monounsaturatedFat, 'г',
                        per100g.monounsaturatedFat),
                    _NdsRow.optional('Полиненасыщенные',
                        total.polyunsaturatedFat, 'г',
                        per100g.polyunsaturatedFat),
                  ]),
                  _NdsSection('Минералы', [
                    _NdsRow.optional('Натрий', total.sodiumMg, 'мг',
                        per100g.sodiumMg),
                    _NdsRow.optional('Холестерин', total.cholesterolMg, 'мг',
                        per100g.cholesterolMg),
                    _NdsRow.optional('Калий', total.potassiumMg, 'мг',
                        per100g.potassiumMg),
                    _NdsRow.optional('Кальций', total.calciumMg, 'мг',
                        per100g.calciumMg),
                    _NdsRow.optional(
                        'Железо', total.ironMg, 'мг', per100g.ironMg),
                  ]),
                  _NdsSection('Витамины', [
                    _NdsRow.optional('Витамин A', total.vitaminAMcg, 'мкг',
                        per100g.vitaminAMcg),
                    _NdsRow.optional('Витамин C', total.vitaminCMg, 'мг',
                        per100g.vitaminCMg),
                    _NdsRow.optional('Витамин D', total.vitaminDMcg, 'мкг',
                        per100g.vitaminDMcg),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Внутренние виджеты
// ─────────────────────────────────────────────────────────────────────────────

class _NdsHeader extends StatelessWidget {
  final String name;
  final double weightGrams;
  const _NdsHeader({required this.name, required this.weightGrams});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${weightGrams.toStringAsFixed(0)} г',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NdsSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _NdsSection(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

/// Строка нутриента в таблице.
///
/// Фабрики:
/// - [_NdsRow.required] — обязательное поле (всегда есть значение)
/// - [_NdsRow.optional] — опциональное поле (null → "N/A")
/// - [_NdsRow.gi] — гликемический индекс со значком категории
class _NdsRow extends StatelessWidget {
  final String label;
  final String valueStr;      // уже отформатированное итоговое значение
  final String? per100Str;    // "(X/100г)" или null
  final bool isLast;

  const _NdsRow._({
    required this.label,
    required this.valueStr,
    this.per100Str,
    this.isLast = false,
  });

  factory _NdsRow.required(
    String label,
    double total,
    String unit,
    double per100, {
    bool isLast = false,
  }) {
    return _NdsRow._(
      label: label,
      valueStr: '${total.toStringAsFixed(1)} $unit',
      per100Str: '(${per100.toStringAsFixed(1)}/100г)',
      isLast: isLast,
    );
  }

  factory _NdsRow.optional(
    String label,
    double? total,
    String unit,
    double? per100, {
    bool isLast = false,
  }) {
    if (total == null) {
      return _NdsRow._(label: label, valueStr: 'N/A', isLast: isLast);
    }
    return _NdsRow._(
      label: label,
      valueStr: '${total.toStringAsFixed(1)} $unit',
      per100Str: per100 != null ? '(${per100.toStringAsFixed(1)}/100г)' : null,
      isLast: isLast,
    );
  }

  factory _NdsRow.gi(int? gi, String? category, {bool isLast = false}) {
    if (gi == null) {
      return _NdsRow._(label: 'Гликемич. индекс', valueStr: 'N/A',
          isLast: isLast);
    }
    final cat =
        category ?? (gi < 55 ? 'low' : gi < 70 ? 'medium' : 'high');
    final label = switch (cat) {
      'low' => 'низкий',
      'medium' => 'средний',
      _ => 'высокий',
    };
    return _NdsRow._(
      label: 'Гликемич. индекс',
      valueStr: '$gi · $label',
      isLast: isLast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNA = valueStr == 'N/A';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isNA ? AppColors.textMuted : AppColors.text,
                ),
              ),
              const Spacer(),
              if (per100Str != null) ...[
                Text(
                  per100Str!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                valueStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isNA ? AppColors.textMuted : AppColors.text,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SourceBadge — публичный виджет (используется и в других местах)
// ─────────────────────────────────────────────────────────────────────────────

class _SourceConfig {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final String? url;
  const _SourceConfig({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.url,
  });
}

/// Маленький чип с иконкой и названием источника данных о нутриентах.
///
/// Параметр [compact] делает чип меньше (для списков ингредиентов).
class SourceBadge extends StatelessWidget {
  final String source;
  final String? sourceUrl;
  final bool compact;

  const SourceBadge({
    super.key,
    required this.source,
    this.sourceUrl,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _sourceConfig(source, sourceUrl);

    return GestureDetector(
      onTap: cfg.url != null
          ? () async {
              final uri = Uri.parse(cfg.url!);
              if (await canLaunchUrl(uri)) launchUrl(uri);
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: cfg.bg,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cfg.icon, size: compact ? 10 : 13, color: cfg.color),
            const SizedBox(width: 4),
            Text(
              cfg.label,
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w600,
                color: cfg.color,
              ),
            ),
            if (cfg.url != null) ...[
              const SizedBox(width: 3),
              Icon(Icons.open_in_new_rounded,
                  size: compact ? 9 : 11,
                  color: cfg.color.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }

  static _SourceConfig _sourceConfig(String source, String? sourceUrl) {
    return switch (source.toLowerCase()) {
      'usda' => _SourceConfig(
          icon: Icons.verified_rounded,
          label: 'USDA FoodData Central',
          color: const Color(0xFF1D4ED8),
          bg: const Color(0xFFDBEAFE),
          url: sourceUrl ?? 'https://fdc.nal.usda.gov/',
        ),
      'fatsecret' => _SourceConfig(
          icon: Icons.search_rounded,
          label: 'FatSecret',
          color: const Color(0xFF15803D),
          bg: const Color(0xFFDCFCE7),
          url: sourceUrl ?? 'https://www.fatsecret.com',
        ),
      'claude' => _SourceConfig(
          icon: Icons.auto_awesome_rounded,
          label: 'Claude AI',
          color: const Color(0xFF6D28D9),
          bg: const Color(0xFFEDE9FE),
          url: 'https://anthropic.com',
        ),
      'cache' => _SourceConfig(
          icon: Icons.storage_rounded,
          label: 'Кэш',
          color: const Color(0xFF6B7280),
          bg: const Color(0xFFF3F4F6),
          url: null,
        ),
      _ => _SourceConfig(
          icon: Icons.bar_chart_rounded,
          label: source,
          color: const Color(0xFF6B7280),
          bg: const Color(0xFFF3F4F6),
          url: sourceUrl,
        ),
    };
  }
}
