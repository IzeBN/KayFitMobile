import 'package:flutter/material.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

/// Layout scaffold for all onboarding steps.
///
/// Puts [primaryCta] (and optional [secondaryCta]) in [bottomNavigationBar]
/// so that Flutter automatically shifts them above the software keyboard when
/// [resizeToAvoidBottomInset] is `true`. This is the fix for P0-3.1: the
/// button is always visible, even when the keyboard is open.
///
/// Usage:
/// ```dart
/// OnboardingScaffold(
///   header: _buildHeader(l10n),
///   body: _HeightStep(...),
///   primaryCta: ObGradientButton(
///     label: l10n.common_next,
///     onTap: _heightCtrl.text.isEmpty ? null : () => _handleHeightNext(l10n),
///   ),
/// )
/// ```
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.header,
    required this.body,
    required this.primaryCta,
    this.secondaryCta,
    this.backgroundColor,
  });

  final Widget header;
  final Widget body;

  /// Primary call-to-action widget, rendered at the bottom above the keyboard.
  final Widget primaryCta;

  /// Optional secondary action (e.g. "Skip" button for optional steps).
  final Widget? secondaryCta;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor ?? OBColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            header,
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              primaryCta,
              if (secondaryCta != null) ...[
                const SizedBox(height: 8),
                secondaryCta!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
