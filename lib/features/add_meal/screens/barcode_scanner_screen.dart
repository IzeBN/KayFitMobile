import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:kayfit/core/api/api_client.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerCtrl;
  late final AnimationController _lineCtrl;

  String? _detectedBarcode;
  bool _torchOn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value != null && value.isNotEmpty && _detectedBarcode != value) {
      setState(() => _detectedBarcode = value);
    }
  }

  Future<void> _lookupBarcode([String? overrideBarcode]) async {
    final barcode = overrideBarcode ?? _detectedBarcode;
    if (barcode == null || _isLoading) return;
    setState(() {
      _isLoading = true;
      if (overrideBarcode != null) _detectedBarcode = overrideBarcode;
    });
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final resp = await apiDio.get(
        '/api/barcode/$barcode',
        queryParameters: {'language': lang},
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.pop(context, data);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Error'),
        backgroundColor: AppColors.accentOver,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showManualInput() {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isRu ? 'Введите штрихкод' : 'Enter barcode',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
                decoration: InputDecoration(
                  hintText: isRu ? '8–14 цифр' : '8–14 digits',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onSubmitted: (v) {
                  if (v.length >= 8) {
                    Navigator.pop(ctx);
                    _lookupBarcode(v);
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final v = ctrl.text;
                  if (v.length >= 8) {
                    Navigator.pop(ctx);
                    _lookupBarcode(v);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isRu ? 'Найти' : 'Search',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Text(l10n.addMeal_barcode_scanning),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded),
            tooltip: Localizations.localeOf(context).languageCode == 'ru'
                ? 'Ввести вручную'
                : 'Enter manually',
            onPressed: _showManualInput,
          ),
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
            ),
            tooltip: _torchOn
                ? l10n.addMeal_barcode_torch_off
                : l10n.addMeal_barcode_torch_on,
            onPressed: () async {
              await _scannerCtrl.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),

          // Overlay
          _ScannerOverlay(lineAnimation: _lineCtrl),

          // Bottom panel
          if (_detectedBarcode != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(
                barcode: _detectedBarcode!,
                isLoading: _isLoading,
                l10n: l10n,
                onConfirm: _lookupBarcode,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner overlay with cutout frame and animated line
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerOverlay extends StatelessWidget {
  final AnimationController lineAnimation;

  const _ScannerOverlay({required this.lineAnimation});

  @override
  Widget build(BuildContext context) {
    const frameW = 300.0;
    const frameH = 200.0;
    const cornerLen = 24.0;
    const cornerWidth = 3.5;
    const overlayColor = Color(0x88000000);

    return LayoutBuilder(builder: (context, constraints) {
      final screenW = constraints.maxWidth;
      final screenH = constraints.maxHeight;
      final left = (screenW - frameW) / 2;
      final top = (screenH - frameH) / 2;

      return Stack(
        children: [
          // Top overlay
          Positioned(
            left: 0, top: 0, right: 0,
            height: top,
            child: const ColoredBox(color: overlayColor),
          ),
          // Bottom overlay
          Positioned(
            left: 0, bottom: 0, right: 0,
            height: screenH - top - frameH,
            child: const ColoredBox(color: overlayColor),
          ),
          // Left overlay
          Positioned(
            left: 0, top: top,
            width: left, height: frameH,
            child: const ColoredBox(color: overlayColor),
          ),
          // Right overlay
          Positioned(
            right: 0, top: top,
            width: left, height: frameH,
            child: const ColoredBox(color: overlayColor),
          ),

          // Corner decorators
          // Top-left
          Positioned(
            left: left, top: top,
            child: _Corner(position: _CornerPosition.topLeft,
                len: cornerLen, width: cornerWidth),
          ),
          // Top-right
          Positioned(
            left: left + frameW - cornerLen, top: top,
            child: _Corner(position: _CornerPosition.topRight,
                len: cornerLen, width: cornerWidth),
          ),
          // Bottom-left
          Positioned(
            left: left, top: top + frameH - cornerLen,
            child: _Corner(position: _CornerPosition.bottomLeft,
                len: cornerLen, width: cornerWidth),
          ),
          // Bottom-right
          Positioned(
            left: left + frameW - cornerLen, top: top + frameH - cornerLen,
            child: _Corner(position: _CornerPosition.bottomRight,
                len: cornerLen, width: cornerWidth),
          ),

          // Animated scan line
          Positioned(
            left: left + 8,
            width: frameW - 16,
            top: top,
            height: frameH,
            child: AnimatedBuilder(
              animation: lineAnimation,
              builder: (_, __) {
                return Align(
                  alignment: Alignment(0, lineAnimation.value * 2 - 1),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

enum _CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _Corner extends StatelessWidget {
  final _CornerPosition position;
  final double len;
  final double width;

  const _Corner({
    required this.position,
    required this.len,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(len, len),
      painter: _CornerPainter(position: position, width: width),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final _CornerPosition position;
  final double width;

  _CornerPainter({required this.position, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    switch (position) {
      case _CornerPosition.topLeft:
        canvas.drawLine(Offset(0, h), Offset(0, 0), paint);
        canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      case _CornerPosition.topRight:
        canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
        canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      case _CornerPosition.bottomLeft:
        canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
        canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      case _CornerPosition.bottomRight:
        canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
        canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom panel shown when barcode is detected
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final String barcode;
  final bool isLoading;
  final AppLocalizations l10n;
  final VoidCallback onConfirm;

  const _BottomPanel({
    required this.barcode,
    required this.isLoading,
    required this.l10n,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_rounded,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.addMeal_barcode_detected,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      barcode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isLoading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.accent,
                    ),
                  ),
                )
              : FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.addMeal_barcode_confirm,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
