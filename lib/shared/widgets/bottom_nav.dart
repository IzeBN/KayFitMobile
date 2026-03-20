import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/journal')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final l10n = AppLocalizations.of(context)!;
    final current = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _AnimatedBottomNav(
        current: current,
        l10n: l10n,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/');
            case 1: context.go('/journal');
            case 2: context.go('/chat');
            case 3: context.go('/settings');
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated bottom nav with pill indicator
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBottomNav extends StatefulWidget {
  final int current;
  final AppLocalizations l10n;
  final ValueChanged<int> onTap;

  const _AnimatedBottomNav({
    required this.current,
    required this.l10n,
    required this.onTap,
  });

  @override
  State<_AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<_AnimatedBottomNav>
    with TickerProviderStateMixin {
  late final List<AnimationController> _scaleCtls;

  @override
  void initState() {
    super.initState();
    _scaleCtls = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
        lowerBound: 0.78,
        upperBound: 1.0,
        value: 1.0,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _scaleCtls) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTap(int i) {
    _scaleCtls[i].reverse().then((_) => _scaleCtls[i].forward());
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavDef(Icons.home_outlined, Icons.home_rounded, widget.l10n.nav_today),
      _NavDef(Icons.menu_book_outlined, Icons.menu_book_rounded, widget.l10n.nav_journal),
      _NavDef(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, widget.l10n.nav_chat),
      _NavDef(Icons.person_outline_rounded, Icons.person_rounded, widget.l10n.nav_settings),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = widget.current == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: ScaleTransition(
                    scale: _scaleCtls[i],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pill background on active
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: active ? 14 : 0,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.accentSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              active ? item.activeIcon : item.icon,
                              key: ValueKey(active),
                              color: active
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            color: active
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDef(this.icon, this.activeIcon, this.label);
}
