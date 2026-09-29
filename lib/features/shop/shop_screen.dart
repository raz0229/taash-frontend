import 'package:flutter/material.dart';
import 'package:taash/l10n/copy.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/auth/auth_controller.dart';
import 'avatars_tab.dart';
import 'thullu_sfx_tab.dart';

/// Shop hosts the two cosmetic currencies: profile avatars and the Bhabhi
/// thullu soundboard. The tab bar opens on Avatars, which is where the
/// own-profile avatar shortcut is expected to land.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiClient api;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No title bar: the two tabs identify the page, and a "Shop" header above
      // them only pushed the grid down.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ShopTabBar(
              index: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 4),
            // IndexedStack keeps each tab's scroll offset and in-flight
            // preview alive when switching, so returning to a tab feels stable.
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  AvatarsTab(
                    key: const ValueKey('avatars'),
                    auth: widget.auth,
                    api: widget.api,
                  ),
                  ThulluSfxTab(
                    key: const ValueKey('thullu-sfx'),
                    auth: widget.auth,
                    api: widget.api,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTabBar extends StatelessWidget {
  const _ShopTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Row(
      children: [
        Expanded(
          child: _ShopTab(
            label: Copy.avatarsTab,
            icon: Icons.face_rounded,
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShopTab(
            label: Copy.thulluSfxTab,
            icon: Icons.graphic_eq_rounded,
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    ),
  );
}

class _ShopTab extends StatelessWidget {
  const _ShopTab({
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
    // Past a 1.4x text scale the icon and label no longer fit side by side, so
    // stack them rather than ellipsing the label away.
    final stacked = textScale > 1.4;
    final labelStyle = TextStyle(
      fontSize: stacked ? 13 : 14,
      fontWeight: FontWeight.w800,
      color: selected ? Colors.white : T.muted,
    );
    return Semantics(
      selected: selected,
      button: true,
      // Announced as a tab, and kept on the widget so tests can assert which
      // half of the Shop is showing.
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? T.pine : T.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? T.ochre : T.outline.withValues(alpha: .65),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: stacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected ? T.ochre : T.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: selected ? T.ochre : T.muted,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
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
