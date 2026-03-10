import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/emotion_picker.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'package:dio/dio.dart';

enum _InputMode { choose, text, voice, photo }

class AddMealSheet extends ConsumerStatefulWidget {
  const AddMealSheet({super.key});

  @override
  ConsumerState<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<AddMealSheet> {
  _InputMode _mode = _InputMode.choose;
  String? _emotion;
  bool _loading = false;
  bool _needsSubscription = false;

  final _textController = TextEditingController();
  final _textFocus = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  final Set<int> _selected = {};
  final Map<int, double?> _itemWeights = {};

  // Language code, updated in build()
  String _lang = 'en';

  // Voice
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _parseText(String text, String lang) async {
    setState(() => _loading = true);
    try {
      final resp = await apiDio.post('/api/parse_meal_suggestions', data: {
        'text': text,
        'language': lang,
      });
      final items = (resp.data['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        _suggestions = items;
        _selected.addAll(Iterable.generate(items.length));
        _itemWeights.clear();
        for (int i = 0; i < items.length; i++) {
          _itemWeights[i] = (items[i]['weight_grams'] as num?)?.toDouble();
        }
      });
    } catch (e) {
      _handleError(e, showPaywall: false); // текст — без paywall
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/meal_voice.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecordingAndTranscribe() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _loading = true;
    });
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(_recordPath!, filename: 'voice.m4a'),
      });
      final resp = await apiDio.post('/api/transcribe?language=$_lang', data: form);
      final text = resp.data['text'] as String? ?? '';
      if (text.isNotEmpty) {
        await _parseText(text, _lang);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndRecognizePhoto() async {
    final picker = ImagePicker();
    final lang = _lang; // capture before async gap
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) {
      // Camera cancelled — reset mode back to choose
      if (mounted) setState(() => _mode = _InputMode.choose);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: 'photo.jpg'),
      });
      final resp = await apiDio.post('/api/recognize_photo?language=$lang', data: form);
      if (!mounted) return;
      final error = resp.data['error'] as String?;
      final rawItems = resp.data['items'] as List<dynamic>?;
      if (error != null && error.isNotEmpty) {
        _handleError(Exception(error));
      } else if (rawItems != null && rawItems.isNotEmpty) {
        final items = rawItems.map((e) => e as Map<String, dynamic>).toList();
        setState(() {
          _suggestions = items;
          _selected.addAll(Iterable.generate(items.length));
          _itemWeights.clear();
          for (int i = 0; i < items.length; i++) {
            _itemWeights[i] = (items[i]['weight_grams'] as num?)?.toDouble();
          }
        });
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSelected() async {
    if (_selected.isEmpty || _emotion == null) return;
    setState(() => _loading = true);
    try {
      final items = _selected.map((i) {
        final s = _suggestions[i];
        final suggestions = s['suggestions'] as List<dynamic>?;
        final base = suggestions != null && suggestions.isNotEmpty
            ? Map<String, dynamic>.from(suggestions[0] as Map<String, dynamic>)
            : Map<String, dynamic>.from(s);
        // Recalculate with actual weight if changed
        final actualWeight = _itemWeights[i] ?? (s['weight_grams'] as num?)?.toDouble() ?? 100.0;
        final cal100 = (base['calories_per_100g'] as num?)?.toDouble();
        if (cal100 != null && actualWeight > 0) {
          final k = actualWeight / 100.0;
          base['calories'] = (cal100 * k).roundToDouble();
          base['protein'] = ((base['protein_per_100g'] as num?)?.toDouble() ?? 0) * k;
          base['fat'] = ((base['fat_per_100g'] as num?)?.toDouble() ?? 0) * k;
          base['carbs'] = ((base['carbs_per_100g'] as num?)?.toDouble() ?? 0) * k;
        }
        base['weight_grams'] = actualWeight;
        return base;
      }).toList();

      await apiDio.post('/api/meals/add_selected', data: {
        'emotion': _emotion,
        'items': items,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// [showPaywall] — true для фото/голоса, false для текста.
  void _handleError(Object e, {bool showPaywall = true}) {
    if (!mounted) return;
    final isPayment = e is DioException && e.error is PaymentRequiredException;
    if (isPayment && showPaywall) {
      setState(() => _needsSubscription = true);
    } else {
      final msg = isPayment
          ? AppLocalizations.of(context)!.addMeal_subscription_snack
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _lang = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: LoadingOverlay(
        isLoading: _loading,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: _needsSubscription
                ? _PaywallView(onTap: () {
                    Navigator.pop(context);
                    context.push('/tariffs');
                  })
                : _suggestions.isNotEmpty
                ? _SuggestionsView(
                    suggestions: _suggestions,
                    selected: _selected,
                    itemWeights: _itemWeights,
                    emotion: _emotion,
                    onToggle: (i) => setState(() {
                      if (_selected.contains(i)) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    }),
                    onWeightChange: (i, w) => setState(() => _itemWeights[i] = w),
                    onEmotionSelect: (e) => setState(() => _emotion = e),
                    onAdd: _addSelected,
                    l10n: l10n,
                  )
                : _InputView(
                    mode: _mode,
                    textController: _textController,
                    textFocus: _textFocus,
                    isRecording: _isRecording,
                    onModeSelect: (m) {
                      setState(() => _mode = m);
                      if (m == _InputMode.text) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _textFocus.requestFocus();
                        });
                      }
                    },
                    onParseText: () => _parseText(_textController.text, _lang),
                    onStartRecording: _startRecording,
                    onStopRecording: _stopRecordingAndTranscribe,
                    onPickPhoto: _pickAndRecognizePhoto,
                    l10n: l10n,
                  ),
          ),
        ),
      ),
    );
  }
}

class _InputView extends StatelessWidget {
  final _InputMode mode;
  final TextEditingController textController;
  final FocusNode textFocus;
  final bool isRecording;
  final ValueChanged<_InputMode> onModeSelect;
  final VoidCallback onParseText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPickPhoto;
  final AppLocalizations l10n;

  const _InputView({
    required this.mode,
    required this.textController,
    required this.textFocus,
    required this.isRecording,
    required this.onModeSelect,
    required this.onParseText,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPickPhoto,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.addMeal_title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (mode == _InputMode.choose) ...[
          _ModeButton(
            icon: Icons.text_fields,
            label: l10n.addMeal_text,
            onTap: () => onModeSelect(_InputMode.text),
          ),
          const SizedBox(height: 8),
          _ModeButton(
            icon: Icons.mic,
            label: l10n.addMeal_voice,
            requiresSubscription: true,
            onTap: () => onModeSelect(_InputMode.voice),
          ),
          const SizedBox(height: 8),
          _ModeButton(
            icon: Icons.camera_alt,
            label: l10n.addMeal_photo,
            requiresSubscription: true,
            onTap: () {
              onModeSelect(_InputMode.photo);
              onPickPhoto();
            },
          ),
        ],
        if (mode == _InputMode.text) ...[
          TextField(
            controller: textController,
            focusNode: textFocus,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.addMeal_inputHint),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onParseText,
              child: Text(l10n.addMeal_parsing),
            ),
          ),
        ],
        if (mode == _InputMode.voice) ...[
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: isRecording ? onStopRecording : onStartRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isRecording ? AppColors.accentOver : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isRecording ? l10n.addMeal_recording : l10n.addMeal_voice,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool requiresSubscription;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.requiresSubscription = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            if (requiresSubscription)
              const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final Set<int> selected;
  final Map<int, double?> itemWeights;
  final String? emotion;
  final ValueChanged<int> onToggle;
  final void Function(int, double?) onWeightChange;
  final ValueChanged<String> onEmotionSelect;
  final VoidCallback onAdd;
  final AppLocalizations l10n;

  const _SuggestionsView({
    required this.suggestions,
    required this.selected,
    required this.itemWeights,
    required this.emotion,
    required this.onToggle,
    required this.onWeightChange,
    required this.onEmotionSelect,
    required this.onAdd,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final itemWidgets = suggestions.asMap().entries.map((e) {
      final i = e.key;
      final item = e.value;
      final name = item['name'] as String? ?? '';
      final sug = (item['suggestions'] as List<dynamic>?)?.isNotEmpty == true
          ? item['suggestions'][0] as Map<String, dynamic>
          : item;
      final cal100 = (sug['calories_per_100g'] as num?)?.toDouble()
          ?? (sug['calories'] as num?)?.toDouble()
          ?? 0.0;
      final currentWeight = itemWeights[i] ?? 100.0;
      final displayCal = cal100 > 0
          ? (cal100 * currentWeight / 100).toStringAsFixed(0)
          : (sug['calories'] as num?)?.toStringAsFixed(0) ?? '?';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: selected.contains(i),
            onChanged: (_) => onToggle(i),
            title: Text(name),
            subtitle: Text(l10n.addMeal_kcal(displayCal)),
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
            child: _WeightField(
              initialWeight: itemWeights[i],
              onChanged: (w) => onWeightChange(i, w),
              l10n: l10n,
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.addMeal_selectItems,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: itemWidgets,
            ),
          ),
        ),
        const Divider(),
        Text(l10n.addMeal_emotionTitle,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        EmotionPicker(selected: emotion, onSelect: onEmotionSelect),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (selected.isNotEmpty && emotion != null) ? onAdd : null,
            child: Text(l10n.addMeal_add),
          ),
        ),
      ],
    );
  }
}

class _WeightField extends StatefulWidget {
  final double? initialWeight;
  final void Function(double?) onChanged;
  final AppLocalizations l10n;

  const _WeightField({
    required this.initialWeight,
    required this.onChanged,
    required this.l10n,
  });

  @override
  State<_WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<_WeightField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialWeight != null
          ? widget.initialWeight!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: widget.l10n.addMeal_weight_hint,
          suffixText: 'г',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: OBColors.pink, width: 2),
          ),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v);
          widget.onChanged(parsed);
        },
      ),
    );
  }
}

class _PaywallView extends StatelessWidget {
  final VoidCallback onTap;
  const _PaywallView({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: OBColors.gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Text('⭐', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.addMeal_subscription_needed,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.addMeal_subscription_desc,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: OBColors.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: OBColors.buttonShadow,
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.addMeal_choose_tariff,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.addMeal_close, style: const TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
