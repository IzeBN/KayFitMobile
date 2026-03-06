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
      final resp = await apiDio.post('/api/transcribe?language=ru', data: form);
      final text = resp.data['text'] as String? ?? '';
      if (text.isNotEmpty) {
        await _parseText(text, 'ru');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndRecognizePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: 'photo.jpg'),
      });
      final resp = await apiDio.post('/api/recognize_photo?language=ru', data: form);
      final error = resp.data['error'] as String?;
      final rawItems = resp.data['items'] as List<dynamic>?;
      if (error != null && error.isNotEmpty) {
        _handleError(Exception(error));
      } else if (rawItems != null && rawItems.isNotEmpty) {
        final items = rawItems.map((e) => e as Map<String, dynamic>).toList();
        setState(() {
          _suggestions = items;
          _selected.addAll(Iterable.generate(items.length));
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
        return suggestions != null && suggestions.isNotEmpty ? suggestions[0] : s;
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
          ? 'Для этой функции нужна подписка'
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    emotion: _emotion,
                    onToggle: (i) => setState(() {
                      if (_selected.contains(i)) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    }),
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
                    onParseText: () => _parseText(_textController.text, 'ru'),
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
  final String? emotion;
  final ValueChanged<int> onToggle;
  final ValueChanged<String> onEmotionSelect;
  final VoidCallback onAdd;
  final AppLocalizations l10n;

  const _SuggestionsView({
    required this.suggestions,
    required this.selected,
    required this.emotion,
    required this.onToggle,
    required this.onEmotionSelect,
    required this.onAdd,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.addMeal_selectItems,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...suggestions.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final name = item['name'] as String? ?? '';
          final sug = item['suggestions'] as List<dynamic>?;
          final first = sug != null && sug.isNotEmpty ? sug[0] as Map<String, dynamic> : item;
          final cal = (first['calories'] as num?)?.toStringAsFixed(0) ?? '?';

          return CheckboxListTile(
            value: selected.contains(i),
            onChanged: (_) => onToggle(i),
            title: Text(name),
            subtitle: Text('$cal ккал'),
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          );
        }),
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

class _PaywallView extends StatelessWidget {
  final VoidCallback onTap;
  const _PaywallView({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        const Text(
          'Нужна подписка',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Распознавание еды доступно на платном тарифе. Оформите подписку чтобы пользоваться ИИ-функциями.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
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
            child: const Text(
              'Выбрать тариф',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
