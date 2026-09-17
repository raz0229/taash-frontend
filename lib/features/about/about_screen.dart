import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../settings/legal_docs.dart';

/// Credits are configured per build via dart-define (see config/*.json), so
/// the About page stays intact for builds that opt not to ship them.
const creditsDesignedByUrl = String.fromEnvironment('CREDITS_DESGINED_BY');
const creditsDesignerName = String.fromEnvironment('CREDIST_DESIGNER_NAME');
const creditsDevelopedByUrl = String.fromEnvironment('CREDITS_DEVELOPED_BY');
const creditsDeveloperName = String.fromEnvironment('CREDITS_DEVELOPER_NAME');

/// True when at least one credit entry is configured for this build. Used so
/// builds without credits keep the About page pixel-identical to before.
bool get _creditsConfigured =>
    (creditsDesignerName.isNotEmpty && creditsDesignedByUrl.isNotEmpty) ||
    (creditsDeveloperName.isNotEmpty && creditsDevelopedByUrl.isNotEmpty);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 20),
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Image.asset(
            'assets/brand/icon.png',
            width: 125,
            height: 125,
            cacheWidth: 375,
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        Copy.madeForOneMoreRound,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        Copy.bhabhiDaketiBluffAndTissarChausarFamiliar,
        textAlign: TextAlign.center,
        style: TextStyle(color: T.muted, fontSize: 16, height: 1.5),
      ),
      const SizedBox(height: 28),
      const TaashPanel(
        child: Column(
          children: [
            Text(
              'A SherazTech game',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              Copy.virtualCoinsRealCompany,
              style: TextStyle(color: T.muted),
            ),
            SizedBox(height: 8),
            Text(
              Copy.taashonline10012,
              style: TextStyle(fontSize: 12, color: T.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const _CreditsSection(),
      if (_creditsConfigured) const SizedBox(height: 8),
      TextButton(
        onPressed: () => showLegalDoc(context, privacyDoc),
        child: const Text(Copy.privacyPolicy),
      ),
      TextButton(
        onPressed: () => showLegalDoc(context, termsDoc),
        child: const Text(Copy.termsCommunityRules),
      ),
      TextButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: Copy.taashonline,
          applicationVersion: '1.0.0',
        ),
        child: const Text(Copy.openSourceLicenses),
      ),
      const SizedBox(height: 28),
      Center(
        child: Image.asset(
          'assets/brand/splash-screen-inverted.png',
          width: 90,
          height: 90,
          cacheWidth: 270,
        ),
      ),
    ],
  );
}

/// Collapsible "Credits" panel that lists the people behind the game and opens
/// their profiles. Clicking a name launches the associated URL in the browser.
class _CreditsSection extends StatefulWidget {
  const _CreditsSection();
  @override
  State<_CreditsSection> createState() => _CreditsSectionState();
}

class _CreditsSectionState extends State<_CreditsSection> {
  bool open = false;

  static final List<({IconData icon, String role, String name, String url})>
  _entries = [
    if (creditsDesignerName.isNotEmpty && creditsDesignedByUrl.isNotEmpty)
      (
        icon: Icons.palette_outlined,
        role: Copy.designedBy,
        name: creditsDesignerName,
        url: creditsDesignedByUrl,
      ),
    if (creditsDeveloperName.isNotEmpty && creditsDevelopedByUrl.isNotEmpty)
      (
        icon: Icons.code_rounded,
        role: Copy.developedBy,
        name: creditsDeveloperName,
        url: creditsDevelopedByUrl,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    // Reduced-motion builds use plain, non-animated state switching rather
    // than zero-duration animations, which can re-dirty during layout.
    final animated = !MediaQuery.disableAnimationsOf(context);
    return TaashPanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => open = !open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: T.coral.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: T.ochre,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Copy.credits,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            Copy.creditsSubtitle,
                            style: TextStyle(
                              color: T.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (animated)
                      AnimatedRotation(
                        turns: open ? .5 : 0,
                        duration: T.standard,
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: T.muted,
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: T.muted,
                      ),
                  ],
                ),
              ),
            ),
            if (animated)
              AnimatedCrossFade(
                duration: T.standard,
                sizeCurve: Curves.easeInOut,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _content(),
                crossFadeState: open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              )
            else if (open)
              _content(),
          ],
        ),
      ),
    );
  }

  Widget _content() => Column(
    children: [
      const Divider(height: 1, indent: 20, endIndent: 20),
      for (var i = 0; i < _entries.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
        _CreditRow(
          icon: _entries[i].icon,
          role: _entries[i].role,
          name: _entries[i].name,
          url: _entries[i].url,
        ),
      ],
    ],
  );
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.icon,
    required this.role,
    required this.name,
    required this.url,
  });
  final IconData icon;
  final String role, name, url;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _launchCreditUrl(context, url),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: T.mint.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: T.mint),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: T.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  style: const TextStyle(
                    color: T.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, size: 17, color: T.ochre),
        ],
      ),
    ),
  );
}

/// Opens [raw] in an external browser, surfacing the standard notice when the
/// link cannot be opened or is not a valid http(s) URL.
Future<void> _launchCreditUrl(BuildContext context, String raw) async {
  final uri = Uri.tryParse(raw);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
    showNotice(context, Copy.weCouldNotOpenTheLinkPlease);
    return;
  }
  try {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && context.mounted) {
      showNotice(context, Copy.weCouldNotOpenTheLinkPlease);
    }
  } on Exception {
    if (context.mounted) showNotice(context, Copy.weCouldNotOpenTheLinkPlease);
  }
}
