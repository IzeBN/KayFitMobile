import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/emotion_picker.dart';
import 'package:dio/dio.dart';

enum _InputMode { choose, text, voice, photo }
enum _LoadingType { none, voice, photo, parsing }

class AddMealSheet extends ConsumerStatefulWidget {
  final DateTime? mealDate;

  const AddMealSheet({super.key, this.mealDate});

  @override
  ConsumerState<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<AddMealSheet> {
  _InputMode _mode = _InputMode.choose;
  String? _emotion;
  _LoadingType _loadingType = _LoadingType.none;

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

  Future<void> _parseText(String text, String lang, {bool manageLoading = true}) async {
    if (manageLoading) setState(() => _loadingType = _LoadingType.parsing);
    try {
      final resp = await apiDio.post('/api/parse_meal_suggestions', data: {
        'text': text,
        'language': lang,
      });
      final items = (resp.data['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) {
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
      if (manageLoading && mounted) setState(() => _loadingType = _LoadingType.none);
    }
  }

  Future<void> _startRecording() async {
    // Explicitly request microphone permission
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addMeal_mic_denied),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accentOver,
          action: status.isPermanentlyDenied
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.addMeal_open_settings,
                  textColor: Colors.white,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      setState(() => _mode = _InputMode.choose);
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/meal_voice.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopRecordingAndTranscribe() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _loadingType = _LoadingType.voice;
    });
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(_recordPath!, filename: 'voice.m4a'),
      });
      final resp = await apiDio.post('/api/transcribe?language=$_lang', data: form);
      final text = resp.data['text'] as String? ?? '';
      if (text.isNotEmpty) {
        await _parseText(text, _lang, manageLoading: false);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loadingType = _LoadingType.none);
    }
  }

  Future<void> _pickAndRecognizePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final lang = _lang; // capture before async gap
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) {
      // Camera cancelled — reset mode back to choose
      if (mounted) setState(() => _mode = _InputMode.choose);
      return;
    }
    if (!mounted) return;
    setState(() => _loadingType = _LoadingType.photo);
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
      if (mounted) setState(() => _loadingType = _LoadingType.none);
    }
  }

  Future<void> _addSelected() async {
    if (_selected.isEmpty || _emotion == null) return;
    setState(() => _loadingType = _LoadingType.parsing);
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
        if (widget.mealDate != null)
          'date': '${widget.mealDate!.year.toString().padLeft(4, '0')}-'
              '${widget.mealDate!.month.toString().padLeft(2, '0')}-'
              '${widget.mealDate!.day.toString().padLeft(2, '0')}',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loadingType = _LoadingType.none);
    }
  }

  void _handleError(Object e) {
    if (!mounted) return;
    final isPayment = e is DioException && e.error is PaymentRequiredException;
    final msg = isPayment
        ? AppLocalizations.of(context)!.addMeal_subscription_snack
        : '$e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
      child: Stack(
        children: [
          SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: _suggestions.isNotEmpty
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
                    onPickPhoto: _pickAndRecognizePhoto,  // now takes ImageSource
                    l10n: l10n,
                  ),
          ),
          ),  // SafeArea
          // Recognition animation overlay
          if (_loadingType == _LoadingType.voice || _loadingType == _LoadingType.photo)
            _RecognizingOverlay(type: _loadingType, l10n: l10n),
          // Simple overlay for text parsing / saving
          if (_loadingType == _LoadingType.parsing)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ),
        ],
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
  final ValueChanged<ImageSource> onPickPhoto;
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
            onTap: () => onModeSelect(_InputMode.voice),
          ),
          const SizedBox(height: 8),
          _ModeButton(
            icon: Icons.camera_alt,
            label: l10n.addMeal_photo,
            onTap: () async {
              final source = await showModalBottomSheet<ImageSource>(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => _PhotoSourceSheet(l10n: l10n),
              );
              if (source == null) return;
              onModeSelect(_InputMode.photo);
              onPickPhoto(source);
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

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
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
          suffixText: widget.l10n.macro_g,
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

// TODO: SUBSCRIPTION_REQUIRED — _PaywallView removed

// ─── Recognition overlay with animated visuals ────────────────────────────────

class _RecognizingOverlay extends StatefulWidget {
  final _LoadingType type;
  final AppLocalizations l10n;

  const _RecognizingOverlay({required this.type, required this.l10n});

  @override
  State<_RecognizingOverlay> createState() => _RecognizingOverlayState();
}

class _RecognizingOverlayState extends State<_RecognizingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVoice = widget.type == _LoadingType.voice;
    final label = isVoice
        ? widget.l10n.addMeal_recognizing_voice
        : widget.l10n.addMeal_recognizing_photo;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVoice)
            _WaveAnimation(controller: _ctrl)
          else
            _ScanAnimation(controller: _ctrl),
          const SizedBox(height: 28),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          _DotLoading(controller: _ctrl),
        ],
      ),
    );
  }
}

// Equalizer bars for voice
class _WaveAnimation extends StatelessWidget {
  final AnimationController controller;
  const _WaveAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    const barCount = 7;
    const barWidth = 7.0;
    const maxHeight = 56.0;
    const minHeight = 8.0;
    const spacing = 6.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              // Each bar oscillates at different phase
              final phase = (i / barCount) * 2 * 3.14159;
              final sine = (0.5 + 0.5 * _sin(t * 2 * 3.14159 + phase));
              final height = minHeight + (maxHeight - minHeight) * sine;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: AnimatedContainer(
                  duration: Duration.zero,
                  width: barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double _sin(double x) => (x - x.truncate() < 0.5)
      ? 4 * (x - x.truncate()) * (1 - 2 * (x - x.truncate()))
      : -1 + 4 * (x - x.truncate()) * (1 - (x - x.truncate()));
}

// Scanning ring for photo
class _ScanAnimation extends StatelessWidget {
  final AnimationController controller;
  const _ScanAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing soft background
              Opacity(
                opacity: 0.4 + 0.3 * (0.5 + 0.5 * _cos(controller.value * 2 * 3.14159)),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Rotating arc
              Transform.rotate(
                angle: controller.value * 2 * 3.14159,
                child: CustomPaint(
                  size: const Size(88, 88),
                  painter: _ArcPainter(),
                ),
              ),
              // Center icon
              const Icon(Icons.camera_alt_rounded, color: AppColors.accent, size: 32),
            ],
          ),
        );
      },
    );
  }

  double _cos(double x) {
    final v = x - x.truncate();
    return 1 - 8 * v * (1 - v);
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, 1.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated dots label
class _DotLoading extends StatelessWidget {
  final AnimationController controller;
  const _DotLoading({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final count = ((controller.value * 3).floor() % 4);
        return Text(
          '●' * count + '○' * (3 - count),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.accent,
            letterSpacing: 4,
          ),
        );
      },
    );
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  final AppLocalizations l10n;
  const _PhotoSourceSheet({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.addMeal_photo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _SourceOption(
            icon: Icons.camera_alt_rounded,
            label: l10n.addMeal_takePhoto,
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceOption(
            icon: Icons.photo_library_rounded,
            label: l10n.addMeal_choosePhoto,
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.common_cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.onTap});

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
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
