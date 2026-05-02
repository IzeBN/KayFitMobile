import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard wrapper for bottom sheets that provides:
/// - A decorative drag handle at the top (when [draggable] is true).
/// - A close button (×) in the top-right corner (when [showCloseButton] is
///   true). Tapping it calls [onClose] or [Navigator.pop] if [onClose] is
///   null.
/// - Rounded top corners via [borderRadius].
/// - A solid background ([AppColors.surface]) so that
///   `backgroundColor: Colors.transparent` on the parent
///   [showModalBottomSheet] call gives a clean appearance.
///
/// Use together with:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   isDismissible: true,
///   enableDrag: true,
///   showDragHandle: false, // handle is inside this wrapper
///   builder: (_) => DismissibleSheetWrapper(child: MySheetContent()),
/// );
/// ```
class DismissibleSheetWrapper extends StatelessWidget {
  const DismissibleSheetWrapper({
    super.key,
    required this.child,
    this.onClose,
    this.showCloseButton = true,
    this.draggable = true,
    this.dismissibleByBarrier = true,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(20)),
  });

  /// The main content of the sheet.
  final Widget child;

  /// Callback invoked when the × button is pressed. If null,
  /// [Navigator.pop] is called instead.
  final VoidCallback? onClose;

  /// Whether to show the × close button in the top-right corner.
  final bool showCloseButton;

  /// Whether to show the drag handle at the top of the sheet.
  final bool draggable;

  /// Documents the intended barrier-dismiss behaviour; the actual
  /// implementation is controlled by [showModalBottomSheet]'s
  /// `isDismissible` parameter.
  final bool dismissibleByBarrier;

  /// Border radius applied to the container.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          if (draggable)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // ── Close button row ──────────────────────────────────────────
          if (showCloseButton)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4, top: 4),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 20,
                  color: AppColors.textMuted,
                  tooltip: 'Close',
                  onPressed: () {
                    if (onClose != null) {
                      onClose!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),

          // ── Content ───────────────────────────────────────────────────
          child,
        ],
      ),
    );
  }
}
