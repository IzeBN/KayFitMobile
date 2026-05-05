// KF2-CHAT — Chat V2 screen (Kayfit 2.0 redesign).
//
// New AI-coach chat UI built on top of the existing chat infrastructure
// (same API endpoints: GET /api/chat/messages, POST /api/chat/send).
//
// Visual system from JSX prototype (kayfit-screens.jsx ChatScreen):
//   • Monochrome surface: K2Theme tokens (bg / surface / hairline)
//   • User bubble: solid fg background, white text, bottom-right corner flat
//   • AI message: surface background, fg text, bottom-left corner flat
//   • Thinking bubble: inline step list with spinner on last active step +
//     check icons on completed steps
//   • Attach toolbar: camera / mic / barcode circular buttons
//   • Input pill: rounded 22px border, borderless inner TextField, send circle
//
// Gated via --dart-define=KF2_CHAT=true in router.dart.
// The legacy ChatScreen remains untouched at /chat.

import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/ai_consent/ai_consent_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../features/add_meal/screens/barcode_scanner_screen_v2.dart';
import '../../../shared/theme/kayfit2_theme.dart';
import '../../../shared/widgets/kayfit2_tab_bar.dart';
import '../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Voice recorder state
// ─────────────────────────────────────────────────────────────────────────────

enum _VoiceState { idle, recording, transcribing }

// ─────────────────────────────────────────────────────────────────────────────
// Thinking-step model
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one progress step shown in the thinking bubble.
@immutable
class _ThinkingState {
  const _ThinkingState({required this.steps, required this.done});

  final List<String> steps;
  final bool done;

  _ThinkingState withStep(String step) =>
      _ThinkingState(steps: [...steps, step], done: done);

  _ThinkingState markDone() =>
      _ThinkingState(steps: steps, done: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen widget
// ─────────────────────────────────────────────────────────────────────────────

class ChatV2Screen extends ConsumerStatefulWidget {
  const ChatV2Screen({super.key});

  @override
  ConsumerState<ChatV2Screen> createState() => _ChatV2ScreenState();
}

class _ChatV2ScreenState extends ConsumerState<ChatV2Screen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  final List<ChatMessage> _messages = [];
  _ThinkingState? _thinking;

  bool _isLoading = false;
  bool _isSending = false;

  // Voice recording
  final _recorder = AudioRecorder();
  _VoiceState _voiceState = _VoiceState.idle;
  String? _recordPath;

  // Thinking step labels — mirrors the JSX prototype sequence.
  static const _kThinkingSteps = [
    'parsing your message',
    'matching USDA database',
    'cross-checking FatSecret',
    'compiling nutrition data',
  ];

  @override
  void initState() {
    super.initState();
    try {
      AnalyticsService.chatOpened();
    } catch (_) {}
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final resp = await apiDio.get(
        '/api/chat/messages',
        queryParameters: {'limit': 50},
      );
      final list = (resp.data['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
      });
      _scrollToBottom();
    } on Exception {
      // Empty state on load errors — shown via _messages.isEmpty branch.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Send flow ───────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Consent gate — block if consent declined.
    final consent = ref.read(aiConsentProvider);
    if (consent == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI chat unavailable: consent was declined'),
          backgroundColor: K2Colors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final lang = Localizations.localeOf(context).languageCode;
    _textController.clear();
    HapticFeedback.lightImpact();

    final userMsg = ChatMessage(
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isSending = true;
      _thinking = _ThinkingState(steps: [_kThinkingSteps[0]], done: false);
    });
    _scrollToBottom();

    try {
      AnalyticsService.chatMessageSent(_messages.length);
    } catch (_) {}

    // Drip-feed step labels to simulate streaming progress.
    for (var i = 1; i < _kThinkingSteps.length; i++) {
      await Future<void>.delayed(
        Duration(milliseconds: 600 + i * 200),
      );
      if (!mounted) return;
      setState(() {
        _thinking = _thinking?.withStep(_kThinkingSteps[i]);
      });
    }

    try {
      final utcOffsetHours = DateTime.now().timeZoneOffset.inHours;
      final resp = await apiDio.post(
        '/api/chat/send',
        data: {
          'text': text,
          'language': lang,
          'utc_offset_hours': utcOffsetHours,
        },
      );
      final reply = ChatMessage.fromJson(
        resp.data['message'] as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _thinking = null;
        _messages.add(reply);
      });
      try {
        AnalyticsService.chatResponseReceived(_messages.length);
      } catch (_) {}
      _scrollToBottom();
    } on Exception {
      if (!mounted) return;
      setState(() {
        _thinking = null;
        _messages.removeLast(); // remove the optimistic user message
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not reach AI coach. Try again.'),
            backgroundColor: K2Colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── Attach toolbar handlers ─────────────────────────────────────────────────

  /// Opens the KF2 capture screen, waits for a photo, then pushes to
  /// recognizing. After save the router pops back here — no extra hook needed.
  Future<void> _handleCamera() async {
    final photo = await context.push<XFile>('/kf2/capture');
    if (!mounted) return;
    if (photo == null) return;
    final result = await context.push<String>(
      '/kf2/recognizing',
      extra: photo,
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'user',
          content: 'added: $result',
          createdAt: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  /// Handles mic button tap: starts recording, or stops and transcribes.
  Future<void> _handleMic() async {
    if (_voiceState == _VoiceState.transcribing) return;

    if (_voiceState == _VoiceState.recording) {
      await _stopAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission denied'),
          backgroundColor: K2Colors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: status.isPermanentlyDenied
              ? SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      _recordPath = '${dir.path}/chat_voice.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordPath!,
      );
      HapticFeedback.lightImpact();
      if (mounted) setState(() => _voiceState = _VoiceState.recording);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start recording: $e'),
            backgroundColor: K2Colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _stopAndTranscribe() async {
    await _recorder.stop();
    if (!mounted) return;
    setState(() => _voiceState = _VoiceState.transcribing);
    HapticFeedback.lightImpact();

    try {
      final lang = Localizations.localeOf(context).languageCode;
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          _recordPath!,
          filename: 'voice.m4a',
        ),
      });
      final resp =
          await apiDio.post('/api/transcribe?language=$lang', data: form);
      final raw = resp.data;
      final text = raw is Map
          ? (raw['text'] as String? ?? '')
          : (raw?.toString() ?? '');

      if (!mounted) return;
      if (text.isNotEmpty) {
        _textController.text = text;
        // Position cursor at end so user can review before sending.
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        // Auto-send the transcribed text through the normal send path.
        await _send();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not transcribe audio. Please try again.'),
            backgroundColor: K2Colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcription failed: $e'),
            backgroundColor: K2Colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _voiceState = _VoiceState.idle);
    }
  }

  /// Opens the legacy barcode scanner via Navigator (no GoRouter route exists).
  Future<void> _handleBarcode() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const BarcodeScannerScreenV2(),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const t = K2Theme.light;

    return Scaffold(
      backgroundColor: t.bg,
      bottomNavigationBar: Kayfit2TabBar(
        theme: t,
        active: 'chat',
        onTab: (key) {
          if (key == 'journal') context.go('/journal-v2');
        },
        onAdd: () {
          // "+" from chat tab — focus the input field so the user can type.
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            _K2TopBar(
              theme: t,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/journal-v2');
                }
              },
            ),

            // ── Status strip (dot + label + "online") ─────────────────────
            _StatusStrip(theme: t),

            // ── Message list ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: K2Colors.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : _messages.isEmpty && _thinking == null
                      ? _EmptyState(theme: t)
                      : _MessageList(
                          scrollController: _scrollController,
                          messages: _messages,
                          thinking: _thinking,
                          theme: t,
                        ),
            ),

            // ── Attach toolbar ─────────────────────────────────────────────
            _AttachToolbar(
              theme: t,
              onCamera: _handleCamera,
              onMic: _handleMic,
              onBarcode: _handleBarcode,
              voiceState: _voiceState,
            ),

            // ── Input row ──────────────────────────────────────────────────
            _InputPill(
              controller: _textController,
              isSending: _isSending,
              theme: t,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _K2TopBar extends StatelessWidget {
  const _K2TopBar({required this.theme, required this.onBack});

  final K2Theme theme;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(
          bottom: BorderSide(color: t.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.fg, size: 18),
            onPressed: onBack,
            tooltip: 'Back',
          ),
          Expanded(
            child: Text(
              'Coach',
              style: TextStyle(
                fontFamily: K2Fonts.sans,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: t.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status strip — "ai nutritionist · online"
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.theme});

  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(
          bottom: BorderSide(color: t.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: t.fg),
          ),
          const SizedBox(width: 8),
          Text(
            'ai nutritionist',
            style: TextStyle(
              fontFamily: K2Fonts.sans,
              fontSize: 11,
              color: t.fgDim,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            'online',
            style: TextStyle(
              fontFamily: K2Fonts.mono,
              fontSize: 10,
              color: t.fgMute,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.border, width: 0.5),
                color: t.surface,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 24, color: t.fgMute),
            ),
            const SizedBox(height: 16),
            Text(
              'nothing logged yet',
              style: TextStyle(
                fontFamily: K2Fonts.mono,
                fontSize: 13,
                color: t.fgDim,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ask or describe what you ate',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: K2Fonts.sans,
                fontSize: 11,
                color: t.fgMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message list
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.thinking,
    required this.theme,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final _ThinkingState? thinking;
  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (thinking != null ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return _MessageBubble(
            message: messages[index],
            theme: theme,
            isNewest: index == messages.length - 1 && thinking == null,
          );
        }
        // Thinking bubble appended after all messages.
        return _ThinkingBubble(state: thinking!, theme: theme);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single message bubble (user right / AI left)
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.theme,
    required this.isNewest,
  });

  final ChatMessage message;
  final K2Theme theme;
  final bool isNewest;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.isNewest) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final t = widget.theme;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: EdgeInsets.only(
            left: isUser ? 56 : 0,
            right: isUser ? 0 : 56,
            top: 3,
            bottom: 7,
          ),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? K2Colors.accent : t.surface,
                        border: Border.all(color: t.border, width: 0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isUser ? 14 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 14),
                        ),
                      ),
                      child: Text(
                        widget.message.content,
                        style: TextStyle(
                          fontFamily: K2Fonts.sans,
                          fontSize: 14,
                          height: 1.45,
                          color: isUser ? Colors.white : t.fg,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 3, left: 4, right: 4),
                      child: Text(
                        _formatTime(widget.message.createdAt),
                        style: TextStyle(
                          fontFamily: K2Fonts.mono,
                          fontSize: 10,
                          color: t.fgMute,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Thinking bubble — step list with spinner on last active step
// ─────────────────────────────────────────────────────────────────────────────

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble({required this.state, required this.theme});

  final _ThinkingState state;
  final K2Theme theme;

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final steps = widget.state.steps;
    final isDone = widget.state.done;

    return Padding(
      padding: const EdgeInsets.only(right: 56, top: 3, bottom: 7),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border, width: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Last active step — spinner; earlier steps — check.
                      if (i == steps.length - 1 && !isDone)
                        _SpinnerDot(controller: _spinCtrl, color: t.fgDim)
                      else
                        Icon(Icons.check_rounded,
                            size: 11, color: t.fgDim),
                      const SizedBox(width: 8),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontFamily: K2Fonts.mono,
                          fontSize: 11,
                          color: t.fgDim,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spinning ring dot that mirrors the JSX `kfSpin` CSS animation.
class _SpinnerDot extends StatelessWidget {
  const _SpinnerDot({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * math.pi,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            // Clip the top-right arc so it appears as an open ring (the
            // "borderTopColor: transparent" equivalent from CSS).
            child: ClipPath(
              clipper: _ArcClipper(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Clips away the top quadrant of a circle to mimic `border-top transparent`.
class _ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
    return path;
  }

  @override
  bool shouldReclip(_ArcClipper oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Attach toolbar — camera / mic / barcode
// ─────────────────────────────────────────────────────────────────────────────

class _AttachToolbar extends StatelessWidget {
  const _AttachToolbar({
    required this.theme,
    required this.onCamera,
    required this.onMic,
    required this.onBarcode,
    required this.voiceState,
  });

  final K2Theme theme;
  final VoidCallback onCamera;
  final Future<void> Function() onMic;
  final VoidCallback onBarcode;
  final _VoiceState voiceState;

  @override
  Widget build(BuildContext context) {
    final t = theme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: t.bg,
      child: Row(
        children: [
          // Camera button
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: onCamera,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.border, width: 0.5),
                  color: t.surface,
                ),
                child: Icon(Icons.camera_alt_outlined, size: 15, color: t.fg),
              ),
            ),
          ),

          // Mic button — reflects voice state
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: voiceState == _VoiceState.transcribing ? null : onMic,
              child: _MicButton(theme: t, voiceState: voiceState),
            ),
          ),

          // Barcode button
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: onBarcode,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.border, width: 0.5),
                  color: t.surface,
                ),
                child:
                    Icon(Icons.barcode_reader, size: 15, color: t.fg),
              ),
            ),
          ),

          // "Recording…" / "Transcribing…" label next to mic
          if (voiceState != _VoiceState.idle) ...[
            Text(
              voiceState == _VoiceState.recording
                  ? 'Recording…'
                  : 'Transcribing…',
              style: TextStyle(
                fontFamily: K2Fonts.mono,
                fontSize: 11,
                color: voiceState == _VoiceState.recording
                    ? K2Colors.error
                    : t.fgDim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated mic button that pulses red while recording and shows a spinner
/// while transcribing.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.theme, required this.voiceState});

  final K2Theme theme;
  final _VoiceState voiceState;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceState != widget.voiceState) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.voiceState == _VoiceState.recording) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final isRecording = widget.voiceState == _VoiceState.recording;
    final isTranscribing = widget.voiceState == _VoiceState.transcribing;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final scale = isRecording ? (1.0 + 0.12 * _pulseCtrl.value) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording
                    ? K2Colors.error
                    : isTranscribing
                        ? t.fgDim
                        : t.border,
                width: isRecording ? 1.5 : 0.5,
              ),
              color: isRecording
                  ? K2Colors.error.withValues(alpha: 0.12)
                  : t.surface,
            ),
            child: isTranscribing
                ? Padding(
                    padding: const EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: t.fgDim,
                    ),
                  )
                : Icon(
                    isRecording
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded,
                    size: 15,
                    color: isRecording ? K2Colors.error : t.fg,
                  ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input pill
// ─────────────────────────────────────────────────────────────────────────────

class _InputPill extends StatefulWidget {
  const _InputPill({
    required this.controller,
    required this.isSending,
    required this.theme,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final K2Theme theme;
  final VoidCallback onSend;

  @override
  State<_InputPill> createState() => _InputPillState();
}

class _InputPillState extends State<_InputPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sendCtrl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _sendCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _sendCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has == _hasText) return;
    _hasText = has;
    if (has) {
      _sendCtrl.forward();
    } else {
      _sendCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: t.bg,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rounded pill text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.border, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontFamily: K2Fonts.sans,
                  fontSize: 14,
                  color: t.fg,
                ),
                decoration: InputDecoration(
                  hintText: 'ask or describe what you ate',
                  hintStyle: TextStyle(
                    fontFamily: K2Fonts.sans,
                    fontSize: 14,
                    color: t.fgMute,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send circle — elastic scale in/out
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _sendCtrl,
              curve: Curves.elasticOut,
              reverseCurve: Curves.easeInCubic,
            ),
            child: GestureDetector(
              onTap: widget.isSending ? null : widget.onSend,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText ? t.fg : t.border,
                ),
                child: widget.isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: _hasText ? t.bg : t.fgMute,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
