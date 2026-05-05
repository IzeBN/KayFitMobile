import 'package:flutter/material.dart';

import '../../../shared/theme/kayfit2_theme.dart';

/// Dashed-border CTA that expands to a textarea for AI correction.
///
/// Compact mode: shows "✨ tell AI to correct" dashed row.
/// Expanded mode: shows a TextField with placeholder + Cancel/Apply buttons.
/// Error appears inline under the textarea in red.
class KF2AiCorrectSection extends StatefulWidget {
  const KF2AiCorrectSection({
    super.key,
    required this.onApply,
    required this.theme,
  });

  /// Called with the correction text when the user taps Apply.
  /// Returns an error message string on failure, or null on success.
  final Future<String?> Function(String correction) onApply;
  final K2Theme theme;

  @override
  State<KF2AiCorrectSection> createState() => _KF2AiCorrectSectionState();
}

class _KF2AiCorrectSectionState extends State<KF2AiCorrectSection> {
  bool _expanded = false;
  bool _loading = false;
  String? _error;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    setState(() {
      _expanded = true;
      _error = null;
    });
    Future.delayed(
      const Duration(milliseconds: 80),
      () => _focus.requestFocus(),
    );
  }

  void _cancel() {
    setState(() {
      _expanded = false;
      _error = null;
    });
    _ctrl.clear();
    _focus.unfocus();
  }

  Future<void> _apply() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _focus.unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final error = await widget.onApply(text);
      if (!mounted) return;
      if (error != null) {
        setState(() => _error = error);
      } else {
        setState(() => _expanded = false);
        _ctrl.clear();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _expanded ? _buildExpanded(t) : _buildCompact(t),
      ),
    );
  }

  Widget _buildCompact(K2Theme t) {
    return GestureDetector(
      onTap: _open,
      child: _DashedBorderBox(
        borderRadius: 10,
        color: t.borderStrong,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                'tell AI to correct',
                style: TextStyle(
                  fontFamily: K2Fonts.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: t.fgDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(K2Theme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'tell AI to correct',
              style: TextStyle(
                fontFamily: K2Fonts.sans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.fg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            fontFamily: K2Fonts.sans,
            fontSize: 14,
            color: t.fg,
          ),
          decoration: InputDecoration(
            hintText: 'no rice, add quinoa…',
            hintStyle: TextStyle(
              fontFamily: K2Fonts.sans,
              fontSize: 14,
              color: t.fgMute,
            ),
            filled: true,
            fillColor: t.surface,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.fg),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: 12,
              color: K2Colors.error,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _cancel,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: K2Fonts.sans,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: t.fgDim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _loading ? null : _apply,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _loading ? t.fg.withValues(alpha: 0.5) : t.fg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: t.bg,
                            ),
                          )
                        : Text(
                            'Apply',
                            style: TextStyle(
                              fontFamily: K2Fonts.sans,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.bg,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Dashed border painter ────────────────────────────────────────────────────

class _DashedBorderBox extends StatelessWidget {
  const _DashedBorderBox({
    required this.child,
    required this.borderRadius,
    required this.color,
  });

  final Widget child;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        borderRadius: borderRadius,
        color: color,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
  });

  final double borderRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashGap = 4.0;

    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rRect);
    final dashPath = Path();

    double distance = 0;
    bool draw = true;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashGap;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
