import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kayfit/core/analytics/analytics_service.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:dio/dio.dart';

enum _InputMode { choose, text, voice, photo }
enum _LoadingType { none, voice, photo, parsing }

// ─────────────────────────────────────────────────────────────────────────────
// Method card config
// ─────────────────────────────────────────────────────────────────────────────

class _MethodConfig {
  final IconData icon;
  final String emoji;
  final List<Color> gradient;
  final Color shadowColor;
  final _InputMode mode;
  String label(_) => '';
  String desc(_) => '';

  const _MethodConfig({
    required this.icon,
    required this.emoji,
    required this.gradient,
    required this.shadowColor,
    required this.mode,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AddMealSheet
// ─────────────────────────────────────────────────────────────────────────────

class AddMealSheet extends ConsumerStatefulWidget {
  final DateTime? mealDate;
  const AddMealSheet({super.key, this.mealDate});

  @override
  ConsumerState<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<AddMealSheet>
    with TickerProviderStateMixin {
  _InputMode _mode = _InputMode.choose;
  String? _emotion;
  _LoadingType _loadingType = _LoadingType.none;

  final _textController = TextEditingController();
  final _textFocus = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  final Set<int> _selected = {};
  final Map<int, double?> _itemWeights = {};

  String _lang = 'en';

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;
  DateTime? _recordStart;

  // Sheet entrance
  late final AnimationController _sheetCtrl;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;

  // Mode transition
  late final AnimationController _modeCtrl;

  @override
  void initState() {
    super.initState();
    AnalyticsService.mealAddOpened();

    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _sheetFade = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));

    _modeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..value = 1.0;

    _sheetCtrl.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    _recorder.dispose();
    _sheetCtrl.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_InputMode mode) async {
    HapticFeedback.selectionClick();
    if (mode != _InputMode.choose) {
      AnalyticsService.addMealModeSelected(mode.name);
    }
    await _modeCtrl.reverse();
    setState(() => _mode = mode);
    _modeCtrl.forward();
    if (mode == _InputMode.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _textFocus.requestFocus());
    }
  }

  Future<void> _parseText(String text, String lang,
      {bool manageLoading = true}) async {
    if (manageLoading) setState(() => _loadingType = _LoadingType.parsing);
    try {
      final resp = await apiDio.post('/api/parse_meal_suggestions',
          data: {'text': text, 'language': lang});
      final items = (resp.data['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (mounted) {
        setState(() {
          _suggestions = items;
          _selected.addAll(Iterable.generate(items.length));
          _itemWeights.clear();
          for (int i = 0; i < items.length; i++) {
            _itemWeights[i] =
                (items[i]['weight_grams'] as num?)?.toDouble();
          }
        });
        AnalyticsService.mealParsed(items.length, _mode.name);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (manageLoading && mounted)
        setState(() => _loadingType = _LoadingType.none);
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.addMeal_mic_denied),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accentOver,
        action: status.isPermanentlyDenied
            ? SnackBarAction(
                label: AppLocalizations.of(context)!.addMeal_open_settings,
                textColor: Colors.white,
                onPressed: openAppSettings)
            : null,
      ));
      _switchMode(_InputMode.choose);
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/meal_voice.m4a';
    await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordPath!);
    _recordStart = DateTime.now();
    AnalyticsService.mealVoiceRecordStarted();
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopRecordingAndTranscribe() async {
    await _recorder.stop();
    final dur = _recordStart != null
        ? DateTime.now().difference(_recordStart!).inSeconds
        : 0;
    AnalyticsService.mealVoiceRecordStopped(dur);
    setState(() {
      _isRecording = false;
      _loadingType = _LoadingType.voice;
    });
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(_recordPath!,
            filename: 'voice.m4a'),
      });
      final resp =
          await apiDio.post('/api/transcribe?language=$_lang', data: form);
      // Handle both {text: "..."} and plain string responses
      final raw = resp.data;
      final text = raw is Map
          ? (raw['text'] as String? ?? '')
          : (raw?.toString() ?? '');
      if (text.isNotEmpty) {
        await _parseText(text, _lang, manageLoading: false);
      }
      // If we still have no suggestions after parsing, go back to choose screen
      if (mounted && _suggestions.isEmpty) {
        _switchMode(_InputMode.choose);
      }
    } catch (e) {
      _handleError(e);
      if (mounted) _switchMode(_InputMode.choose);
    } finally {
      if (mounted) setState(() => _loadingType = _LoadingType.none);
    }
  }

  Future<void> _pickAndRecognizePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final lang = _lang;
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) {
      if (mounted) _switchMode(_InputMode.choose);
      return;
    }
    if (source == ImageSource.gallery) {
      AnalyticsService.addMealPhotoFromGallery();
    } else {
      AnalyticsService.addMealPhotoTaken();
    }
    if (!mounted) return;
    setState(() => _loadingType = _LoadingType.photo);
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: 'photo.jpg'),
      });
      final resp =
          await apiDio.post('/api/recognize_photo?language=$lang', data: form);
      if (!mounted) return;
      final error = resp.data['error'] as String?;
      final rawItems = resp.data['items'] as List<dynamic>?;
      if (error != null && error.isNotEmpty) {
        _handleError(Exception(error));
      } else if (rawItems != null && rawItems.isNotEmpty) {
        final items =
            rawItems.map((e) => e as Map<String, dynamic>).toList();
        setState(() {
          _suggestions = items;
          _selected.addAll(Iterable.generate(items.length));
          _itemWeights.clear();
          for (int i = 0; i < items.length; i++) {
            _itemWeights[i] =
                (items[i]['weight_grams'] as num?)?.toDouble();
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
    HapticFeedback.mediumImpact();
    setState(() => _loadingType = _LoadingType.parsing);
    try {
      final items = _selected.map((i) {
        final s = _suggestions[i];
        final suggestions = s['suggestions'] as List<dynamic>?;
        final base = suggestions != null && suggestions.isNotEmpty
            ? Map<String, dynamic>.from(
                suggestions[0] as Map<String, dynamic>)
            : Map<String, dynamic>.from(s);
        final actualWeight = _itemWeights[i] ??
            (s['weight_grams'] as num?)?.toDouble() ??
            100.0;
        final cal100 = (base['calories_per_100g'] as num?)?.toDouble();
        if (cal100 != null && actualWeight > 0) {
          final k = actualWeight / 100.0;
          base['calories'] = (cal100 * k).roundToDouble();
          base['protein'] =
              ((base['protein_per_100g'] as num?)?.toDouble() ?? 0) * k;
          base['fat'] =
              ((base['fat_per_100g'] as num?)?.toDouble() ?? 0) * k;
          base['carbs'] =
              ((base['carbs_per_100g'] as num?)?.toDouble() ?? 0) * k;
        }
        base['weight_grams'] = actualWeight;
        return base;
      }).toList();

      await apiDio.post('/api/meals/add_selected', data: {
        'emotion': _emotion,
        'items': items,
        if (widget.mealDate != null)
          'date':
              '${widget.mealDate!.year.toString().padLeft(4, '0')}-'
              '${widget.mealDate!.month.toString().padLeft(2, '0')}-'
              '${widget.mealDate!.day.toString().padLeft(2, '0')}',
      });
      final totalCal = items
          .fold<double>(
              0, (s, it) => s + ((it['calories'] as num?)?.toDouble() ?? 0))
          .round();
      AnalyticsService.mealSaved(
          itemCount: items.length,
          mode: _mode.name,
          emotion: _emotion,
          totalCalories: totalCal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AnalyticsService.mealSaveFailed('$e');
      _handleError(e);
    } finally {
      if (mounted) setState(() => _loadingType = _LoadingType.none);
    }
  }

  void _handleError(Object e) {
    if (!mounted) return;
    final isPayment =
        e is DioException && e.error is PaymentRequiredException;
    final msg = isPayment
        ? AppLocalizations.of(context)!.addMeal_subscription_snack
        : '$e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accentOver,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _lang = Localizations.localeOf(context).languageCode;
    final isRu = _lang == 'ru';

    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: _sheetFade,
      child: SlideTransition(
        position: _sheetSlide,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  _DragHandle(),

                  // Header
                  _SheetHeader(
                    mode: _mode,
                    l10n: l10n,
                    onBack: _suggestions.isNotEmpty
                        ? () => setState(() {
                              _suggestions.clear();
                              _selected.clear();
                              _itemWeights.clear();
                            })
                        : _mode != _InputMode.choose
                            ? () => _switchMode(_InputMode.choose)
                            : null,
                  ),

                  // Content
                  FadeTransition(
                    opacity: _modeCtrl,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
                        child: _suggestions.isNotEmpty
                            ? _SuggestionsView(
                                suggestions: _suggestions,
                                selected: _selected,
                                itemWeights: _itemWeights,
                                emotion: _emotion,
                                onToggle: (i) => setState(() {
                                  _selected.contains(i)
                                      ? _selected.remove(i)
                                      : _selected.add(i);
                                }),
                                onWeightChange: (i, w) =>
                                    setState(() => _itemWeights[i] = w),
                                onEmotionSelect: (e) {
                                  setState(() => _emotion = e);
                                  AnalyticsService.emotionSelected(e);
                                },
                                onAdd: _addSelected,
                                l10n: l10n,
                              )
                            : _mode == _InputMode.choose
                                ? _ChooseView(
                                    l10n: l10n,
                                    isRu: isRu,
                                    onText: () => _switchMode(_InputMode.text),
                                    onVoice: () async {
                                      _switchMode(_InputMode.voice);
                                      Future.delayed(
                                          const Duration(milliseconds: 350),
                                          _startRecording);
                                    },
                                    onPhoto: () async {
                                      final source =
                                          await showModalBottomSheet<ImageSource>(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            _PhotoSourceSheet(l10n: l10n),
                                      );
                                      if (source == null) return;
                                      _switchMode(_InputMode.photo);
                                      _pickAndRecognizePhoto(source);
                                    },
                                  )
                                : _mode == _InputMode.text
                                    ? _TextView(
                                        controller: _textController,
                                        focus: _textFocus,
                                        l10n: l10n,
                                        isRu: isRu,
                                        onParse: () async {
                                          AnalyticsService.addMealTextSubmitted(_textController.text.length);
                                          _parseText(_textController.text, _lang);
                                        },
                                      )
                                    : _VoiceView(
                                        isRecording: _isRecording,
                                        recordStart: _recordStart,
                                        l10n: l10n,
                                        onToggle: _isRecording
                                            ? _stopRecordingAndTranscribe
                                            : _startRecording,
                                      ),
                      ),
                    ),
                  ),
                ],
              ),

              // Loading overlays
              if (_loadingType == _LoadingType.voice ||
                  _loadingType == _LoadingType.photo)
                _RecognizingOverlay(type: _loadingType, l10n: l10n),
              if (_loadingType == _LoadingType.parsing)
                _SavingOverlay(l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag handle
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet header
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final _InputMode mode;
  final AppLocalizations l10n;
  final VoidCallback? onBack;

  const _SheetHeader(
      {required this.mode, required this.l10n, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              l10n.addMeal_title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Choose view — 3 big animated method cards
// ─────────────────────────────────────────────────────────────────────────────

class _ChooseView extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isRu;
  final VoidCallback onText;
  final VoidCallback onVoice;
  final VoidCallback onPhoto;

  const _ChooseView({
    required this.l10n,
    required this.isRu,
    required this.onText,
    required this.onVoice,
    required this.onPhoto,
  });

  @override
  State<_ChooseView> createState() => _ChooseViewState();
}

class _ChooseViewState extends State<_ChooseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final ru = widget.isRu;

    final methods = [
      _MethodData(
        icon: Icons.camera_alt_rounded,
        gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
        shadowColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        title: ru ? 'Фото блюда' : 'Photo',
        desc: ru
            ? 'Сфотографируй — AI распознает состав за 5 сек'
            : 'Take a photo — AI identifies macros in 5 sec',
        badge: '📸',
        onTap: widget.onPhoto,
      ),
      _MethodData(
        icon: Icons.mic_rounded,
        gradient: const [Color(0xFF059669), Color(0xFF10B981)],
        shadowColor: const Color(0xFF059669),
        bgColor: const Color(0xFFF0FDF4),
        title: ru ? 'Голосом' : 'By voice',
        desc: ru
            ? '«Съел борщ 300 мл» — просто скажи'
            : 'Say "I ate soup 300ml" — that\'s it',
        badge: '🎤',
        onTap: widget.onVoice,
      ),
      _MethodData(
        icon: Icons.edit_rounded,
        gradient: const [Color(0xFFEA580C), Color(0xFFF97316)],
        shadowColor: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
        title: ru ? 'Текстом' : 'Type it',
        desc: ru
            ? 'Напиши что съел — AI посчитает КБЖУ'
            : 'Describe your meal — AI counts macros',
        badge: '✍️',
        onTap: widget.onText,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: methods.asMap().entries.map((e) {
        final delay = e.key * 0.15;
        final fade = CurvedAnimation(
          parent: _stagger,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
        ));
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: _MethodCard(data: e.value),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MethodData {
  final IconData icon;
  final List<Color> gradient;
  final Color shadowColor;
  final Color bgColor;
  final String title;
  final String desc;
  final String badge;
  final VoidCallback onTap;

  const _MethodData({
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.bgColor,
    required this.title,
    required this.desc,
    required this.badge,
    required this.onTap,
  });
}

class _MethodCard extends StatefulWidget {
  final _MethodData data;
  const _MethodCard({required this.data});

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          d.onTap();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: Container(
          decoration: BoxDecoration(
            color: d.bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: d.shadowColor.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Gradient icon badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: d.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: d.shadowColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(d.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            d.badge,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            d.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.desc,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: d.gradient.first,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice view — animated recording UI
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceView extends StatefulWidget {
  final bool isRecording;
  final DateTime? recordStart;
  final AppLocalizations l10n;
  final VoidCallback onToggle;

  const _VoiceView({
    required this.isRecording,
    required this.recordStart,
    required this.l10n,
    required this.onToggle,
  });

  @override
  State<_VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<_VoiceView>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _timerCtrl;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (widget.isRecording && widget.recordStart != null) {
          setState(() {
            _elapsed =
                DateTime.now().difference(widget.recordStart!).inSeconds;
          });
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _timerCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final recording = widget.isRecording;
    final l10n = widget.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              recording ? l10n.addMeal_recording : l10n.addMeal_voice,
              key: ValueKey(recording),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: recording ? AppColors.accentOver : AppColors.textMuted,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Central mic button with ripple rings
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple rings (only when recording)
                if (recording) ...[
                  _RippleRing(ctrl: _pulseCtrl, delay: 0.0, maxRadius: 90, color: AppColors.accentOver),
                  _RippleRing(ctrl: _pulseCtrl, delay: 0.4, maxRadius: 90, color: AppColors.accentOver),
                  _RippleRing(ctrl: _pulseCtrl, delay: 0.8, maxRadius: 90, color: AppColors.accentOver),
                ] else ...[
                  _RippleRing(ctrl: _pulseCtrl, delay: 0.0, maxRadius: 90, color: AppColors.accent),
                  _RippleRing(ctrl: _pulseCtrl, delay: 0.5, maxRadius: 90, color: AppColors.accent),
                ],

                // Main button
                GestureDetector(
                  onTap: widget.onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: recording ? 88 : 80,
                    height: recording ? 88 : 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: recording
                            ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                            : [const Color(0xFF059669), const Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (recording ? AppColors.accentOver : AppColors.accent)
                              .withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      recording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timer
          AnimatedOpacity(
            opacity: recording ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              _formatTime(_elapsed),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Waveform (only when recording)
          if (recording)
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) => _WaveformBars(t: _waveCtrl.value),
            ),

          const SizedBox(height: 8),

          Text(
            recording
                ? (Localizations.localeOf(context).languageCode == 'ru'
                    ? 'Нажмите ещё раз чтобы остановить'
                    : 'Tap again to stop')
                : (Localizations.localeOf(context).languageCode == 'ru'
                    ? 'Нажмите чтобы начать запись'
                    : 'Tap to start recording'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  final double maxRadius;
  final Color color;

  const _RippleRing({
    required this.ctrl,
    required this.delay,
    required this.maxRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value + delay) % 1.0);
        final radius = maxRadius * t;
        final opacity = (1.0 - t) * 0.35;
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: opacity),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final double t;
  const _WaveformBars({required this.t});

  @override
  Widget build(BuildContext context) {
    const count = 24;
    return SizedBox(
      width: 200,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(count, (i) {
          final phase = (i / count) * 2 * math.pi;
          final height = 4.0 +
              22.0 *
                  (0.5 +
                      0.5 *
                          math.sin(t * 2 * math.pi + phase) *
                          math.sin(i * 0.4));
          return Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: AppColors.accentOver.withValues(alpha: 0.7 + 0.3 * (height / 26)),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text view
// ─────────────────────────────────────────────────────────────────────────────

class _TextView extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final AppLocalizations l10n;
  final bool isRu;
  final VoidCallback onParse;

  const _TextView({
    required this.controller,
    required this.focus,
    required this.l10n,
    required this.isRu,
    required this.onParse,
  });

  @override
  State<_TextView> createState() => _TextViewState();
}

class _TextViewState extends State<_TextView> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final ru = widget.isRu;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hint chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ru ? 'Гречка 200г, курица 150г' : 'Oatmeal 200g, chicken 150g',
            ru ? 'Борщ 300мл, хлеб 2 куска' : 'Soup 300ml, 2 bread slices',
          ].map((hint) => GestureDetector(
            onTap: () {
              widget.controller.text = hint;
              widget.focus.requestFocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          )).toList(),
        ),

        const SizedBox(height: 14),

        // Text input
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focus,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.addMeal_inputHint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(
                fontSize: 15, color: AppColors.text, height: 1.5),
          ),
        ),

        const SizedBox(height: 14),

        // Recognize button
        AnimatedOpacity(
          opacity: _hasText ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _hasText
                    ? const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [AppColors.border, AppColors.border]),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: _hasText ? widget.onParse : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          ru ? 'Распознать с помощью AI' : 'Recognize with AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestions view — beautiful meal result cards
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionsView extends StatefulWidget {
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
  State<_SuggestionsView> createState() => _SuggestionsViewState();
}

class _SuggestionsViewState extends State<_SuggestionsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final canAdd = widget.selected.isNotEmpty && widget.emotion != null;

    // Calculate totals for selected
    double totalCal = 0;
    for (final i in widget.selected) {
      final s = widget.suggestions[i];
      final sug = (s['suggestions'] as List<dynamic>?)?.isNotEmpty == true
          ? s['suggestions'][0] as Map<String, dynamic>
          : s;
      final cal100 = (sug['calories_per_100g'] as num?)?.toDouble() ??
          (sug['calories'] as num?)?.toDouble() ??
          0.0;
      final weight = widget.itemWeights[i] ?? 100.0;
      totalCal += cal100 > 0 ? cal100 * weight / 100 : 0;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total badge
        if (widget.selected.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                '${totalCal.toStringAsFixed(0)} ${l10n.macro_kcal}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),

        const SizedBox(height: 12),

        // Meal cards list
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.suggestions.length,
            itemBuilder: (context, i) {
              final delay = i * 0.12;
              final fade = CurvedAnimation(
                parent: _stagger,
                curve: Interval(delay.clamp(0, 0.7),
                    (delay + 0.4).clamp(0, 1.0),
                    curve: Curves.easeOutCubic),
              );
              final slide = Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(fade);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: _MealResultCard(
                      index: i,
                      item: widget.suggestions[i],
                      selected: widget.selected.contains(i),
                      weight: widget.itemWeights[i],
                      onToggle: () => widget.onToggle(i),
                      onWeightChange: (w) => widget.onWeightChange(i, w),
                      l10n: l10n,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Emotion section
        Text(
          l10n.addMeal_emotionTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        _AnimatedEmotionPicker(
          selected: widget.emotion,
          onSelect: widget.onEmotionSelect,
        ),

        const SizedBox(height: 16),

        // Add button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: canAdd
                  ? const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF16A34A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [AppColors.border, AppColors.border]),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: canAdd
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      )
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: canAdd ? widget.onAdd : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.addMeal_add,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal result card
// ─────────────────────────────────────────────────────────────────────────────

class _MealResultCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool selected;
  final double? weight;
  final VoidCallback onToggle;
  final void Function(double?) onWeightChange;
  final AppLocalizations l10n;

  const _MealResultCard({
    required this.index,
    required this.item,
    required this.selected,
    required this.weight,
    required this.onToggle,
    required this.onWeightChange,
    required this.l10n,
  });

  @override
  State<_MealResultCard> createState() => _MealResultCardState();
}

class _MealResultCardState extends State<_MealResultCard> {
  late final TextEditingController _wCtrl;

  @override
  void initState() {
    super.initState();
    final w = widget.weight ?? 100.0;
    _wCtrl = TextEditingController(text: w.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final l10n = widget.l10n;
    final name = item['name'] as String? ?? '';
    final sug = (item['suggestions'] as List<dynamic>?)?.isNotEmpty == true
        ? item['suggestions'][0] as Map<String, dynamic>
        : item;
    final cal100 = (sug['calories_per_100g'] as num?)?.toDouble() ??
        (sug['calories'] as num?)?.toDouble() ??
        0.0;
    final currentWeight = widget.weight ?? 100.0;
    final displayCal = cal100 > 0
        ? (cal100 * currentWeight / 100).toStringAsFixed(0)
        : (sug['calories'] as num?)?.toStringAsFixed(0) ?? '?';

    final sel = widget.selected;

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: sel ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: sel ? AppColors.accent : AppColors.border,
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel ? [] : AppShadow.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sel ? AppColors.accent : AppColors.textMuted,
                        width: 1.5,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: sel ? AppColors.accentDark : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.addMeal_kcal(displayCal),
                          style: TextStyle(
                            fontSize: 12,
                            color: sel ? AppColors.accent : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Weight field
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: TextField(
                      controller: _wCtrl,
                      keyboardType: TextInputType.number,
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: l10n.macro_g,
                        suffixStyle: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: sel
                            ? Colors.white
                            : AppColors.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: sel ? AppColors.accent : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.accent, width: 2),
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (v) =>
                          widget.onWeightChange(double.tryParse(v)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated emotion picker — scrollable row of big emoji
// ─────────────────────────────────────────────────────────────────────────────

const _emotions = [
  ('😊', 'happy'),
  ('😌', 'calm'),
  ('😴', 'tired'),
  ('🤤', 'hungry'),
  ('😔', 'sad'),
  ('😰', 'anxious'),
  ('😑', 'bored'),
  ('😠', 'angry'),
  ('😟', 'worried'),
  ('😐', 'neutral'),
  ('💬', 'other'),
];

class _AnimatedEmotionPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _AnimatedEmotionPicker(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _emotions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = _emotions[i];
          final sel = selected == e.$2;
          return GestureDetector(
            onTap: () => onSelect(e.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              width: sel ? 64 : 56,
              height: sel ? 64 : 56,
              decoration: BoxDecoration(
                color: sel ? AppColors.accentSoft : AppColors.bg,
                borderRadius: BorderRadius.circular(sel ? 18 : 14),
                border: Border.all(
                  color: sel ? AppColors.accent : AppColors.border,
                  width: sel ? 2 : 1,
                ),
                boxShadow: sel ? AppShadow.sm : null,
              ),
              alignment: Alignment.center,
              child: Text(
                e.$1,
                style: TextStyle(fontSize: sel ? 28 : 24),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recognizing overlay (voice / photo)
// ─────────────────────────────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 1600),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon in gradient circle
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final scale =
                  1.0 + 0.08 * math.sin(_ctrl.value * 2 * math.pi);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isVoice
                          ? [const Color(0xFF059669), const Color(0xFF10B981)]
                          : [const Color(0xFF7C3AED), const Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isVoice
                                ? AppColors.accent
                                : const Color(0xFF7C3AED))
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isVoice
                        ? Icons.graphic_eq_rounded
                        : Icons.camera_enhance_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Localizations.localeOf(context).languageCode == 'ru'
                ? 'AI анализирует данные...'
                : 'AI is analyzing...',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          // Animated dots
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i / 3.0;
                  final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
                  final scale = 0.5 + 0.5 * math.sin(t * math.pi);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isVoice
                              ? AppColors.accent
                              : const Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saving overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SavingOverlay extends StatelessWidget {
  final AppLocalizations l10n;
  const _SavingOverlay({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
              const SizedBox(height: 14),
              Text(
                Localizations.localeOf(context).languageCode == 'ru'
                    ? 'Сохраняем...'
                    : 'Saving...',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo source bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  final AppLocalizations l10n;
  const _PhotoSourceSheet({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            l10n.addMeal_photo,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _PhotoSourceBtn(
            icon: Icons.camera_alt_rounded,
            gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
            label: l10n.addMeal_takePhoto,
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 10),
          _PhotoSourceBtn(
            icon: Icons.photo_library_rounded,
            gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
            label: l10n.addMeal_choosePhoto,
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceBtn extends StatefulWidget {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceBtn({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PhotoSourceBtn> createState() => _PhotoSourceBtnState();
}

class _PhotoSourceBtnState extends State<_PhotoSourceBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
