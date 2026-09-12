import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../settings/legal_docs.dart';

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
