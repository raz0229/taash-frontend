import 'package:flutter/material.dart';
import 'package:taash/l10n/copy.dart';

import '../../core/billing/billing_service.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/auth/auth_controller.dart';
import 'avatars_tab.dart';
import 'coins_shop_tab.dart';
import 'thullu_sfx_tab.dart';
import 'skins_tab.dart';

/// Shop hosts the cosmetic collections, the thullu soundboard, and the Coins
/// Shop. The tab bar opens on Avatars, which is where the own-profile avatar
/// shortcut is expected to land.
class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.auth,
    required this.api,
    this.billing,
    this.initialTab = 0,
  });

  final AuthController auth;
  final ApiClient api;

  /// The Coins Shop needs a billing service. It is optional so a build without
  /// IAP can still open the Shop; the tab then explains that purchases are
  /// unavailable instead of crashing.
  final BillingService? billing;

  /// Index of the tab to open on. [coinsShopTabIndex] is the Coins Shop, and is
  /// what the reward sheet's Purchase Coins button navigates to.
  final int initialTab;

  /// The Coins Shop's position in the tab order.
  static const coinsShopTabIndex = 3;

  /// Number of tabs, so the cycling arithmetic has one source of truth.
  static const tabCount = 4;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, ShopScreen.tabCount - 1).toInt();
  }

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(
        () => _tab = widget.initialTab.clamp(0, ShopScreen.tabCount - 1).toInt(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = widget.billing;
    return Scaffold(
      // No title bar: the tab label identifies the page, and a "Shop" header
      // above it only pushed the grid down.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ShopTabBar(
              index: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  AvatarsTab(
                    key: const ValueKey('avatars'),
                    auth: widget.auth,
                    api: widget.api,
                  ),
                  SkinsTab(
                    key: const ValueKey('skins'),
                    auth: widget.auth,
                    api: widget.api,
                  ),
                  ThulluSfxTab(
                    key: const ValueKey('thullu-sfx'),
                    auth: widget.auth,
                    api: widget.api,
                  ),
                  // The Coins Shop is built only when a billing service exists,
                  // and it is a plain ValueKey so the IndexedStack keeps it
                  // alive across tab switches and the catalog is not refetched.
                  if (billing != null)
                    CoinsShopTab(
                      key: const ValueKey('coins-shop'),
                      auth: widget.auth,
                      billing: billing,
                    )
                  else
                    const _CoinsShopUnavailable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands in for the Coins Shop in a build with no billing service configured.
class _CoinsShopUnavailable extends StatelessWidget {
  const _CoinsShopUnavailable();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 40,
            color: T.muted,
          ),
          const SizedBox(height: 14),
          Text(
            Copy.coinShopUnavailableTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            Copy.coinsShopUnavailableBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.muted),
          ),
        ],
      ),
    ),
  );
}

/// The four Shop tabs, always shown at their full label width.
///
/// Four labelled tabs are wider than a phone, so the bar scrolls instead of
/// squeezing or ellipsing the labels. Selecting a tab slides it to the leading
/// edge, which pulls its neighbour into view: that trailing sliver is what tells
/// the player there are more tabs than fit.
class _ShopTabBar extends StatefulWidget {
  const _ShopTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<_ShopTabBar> createState() => _ShopTabBarState();
}

class _ShopTabBarState extends State<_ShopTabBar> {
  final _controller = ScrollController();
  final _tabKeys = List.generate(
    ShopScreen.tabCount,
    (_) => GlobalKey(debugLabel: 'shopTab'),
  );

  @override
  void initState() {
    super.initState();
    // The tab the Shop opened on can start off-screen — the Coins Shop is last
    // — so it is brought into view before the first frame is presented.
    _scheduleReveal(animate: false);
  }

  @override
  void didUpdateWidget(covariant _ShopTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _scheduleReveal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The reveal needs laid-out geometry, so it runs after the frame that
  /// painted the newly selected tab.
  void _scheduleReveal({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revealSelected(animate: animate),
    );
  }

  /// Pins the selected tab to the leading edge. Whatever fits after it comes
  /// into view, and whatever was before it scrolls away — so stepping from tab
  /// to tab always shows the neighbour still to come.
  void _revealSelected({required bool animate}) {
    if (!mounted) return;
    final target = _tabKeys[widget.index].currentContext;
    if (target == null) return;
    final scrollable = Scrollable.maybeOf(target);
    if (scrollable == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0,
      duration: animate && !MediaQuery.disableAnimationsOf(context)
          ? T.standard
          : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tab(int i) => Padding(
      // The gap lives on the tabs so it scrolls out with them and the
      // leading-most tab still starts hard against the page margin.
      padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
      child: _ShopTab(
        // The key sits on the tab, not on this gap, so revealing a tab pins
        // the tab itself against the edge instead of leaving the gap showing.
        key: _tabKeys[i],
        label: _labelFor(i),
        icon: _iconFor(i),
        selected: widget.index == i,
        onTap: () => widget.onChanged(i),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        // The tabs are direct children of the Shop body, so there is nothing
        // off-screen for the keyboard or a screen reader to escape to.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < ShopScreen.tabCount; i++) tab(i),
          ],
        ),
      ),
    );
  }

  static String _labelFor(int index) => switch (index) {
    0 => Copy.avatarsTab,
    1 => Copy.skinsTab,
    ShopScreen.coinsShopTabIndex => Copy.coinsShopTab,
    _ => Copy.thulluSfxTab,
  };

  static IconData _iconFor(int index) => switch (index) {
    0 => Icons.face_rounded,
    1 => Icons.style_rounded,
    ShopScreen.coinsShopTabIndex => Icons.monetization_on_rounded,
    _ => Icons.graphic_eq_rounded,
  };
}

class _ShopTab extends StatelessWidget {
  const _ShopTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    // Past a 1.4x text scale the icon and label no longer sit comfortably side
    // by side, so they stack. Stacking narrows the tab, which keeps more of the
    // bar readable at the sizes where labels need the most room.
    final stacked = textScale > 1.4;
    final labelStyle = TextStyle(
      fontSize: stacked ? 13 : 14,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    );
    // The bar scrolls, so a tab is never squeezed and the label is never
    // truncated: it wraps onto as many lines as the text scale needs.
    return Semantics(
      selected: selected,
      button: true,
      // Announced as a tab, and kept on the widget so tests can assert which
      // part of the Shop is showing.
      label: label,
      excludeSemantics: true,
      child: Material(
        color: T.pine,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? T.ochre : T.outline,
                width: 1.5,
              ),
            ),
            child: stacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: T.ochre),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: labelStyle,
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: T.ochre),
                      const SizedBox(width: 7),
                      Text(label, style: labelStyle),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
