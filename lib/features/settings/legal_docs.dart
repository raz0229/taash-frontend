import 'package:flutter/material.dart';
import '../../core/theme/taash_theme.dart';

/// One titled block inside a legal document.
class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// A complete legal document that can be pushed as an in-app page, so players
/// never need to leave the app to read it.
class LegalDoc {
  const LegalDoc({required this.title, required this.sections});
  final String title;
  final List<LegalSection> sections;
}

final privacyDoc = LegalDoc(
  title: 'Privacy policy',
  sections: [
    LegalSection(
      '1. Introduction',
      'Taash Online ("the Service") is a card game application developed and operated by SherazTech. '
          'This Privacy Policy explains what information we collect when you use the Service, how we use and '
          'protect it, and the choices you have. By creating an account and using the Service, you agree to the '
          'practices described in this policy.',
    ),
    LegalSection(
      '2. Information we collect',
      'We collect the information you give us directly and information generated while you play:\n\n'
          '• Account information: the display name, email address, country and avatar you choose when you sign up or edit your profile.\n'
          '• Game data: your matches, scores, virtual-coin balance, profile avatars and other items you earn or buy.\n'
          '• Device and usage information: the type of device and operating system you use, app version, and '
          'anonymous usage statistics we use to diagnose issues and improve the Service.\n'
          '• Communications: messages you send us, for example when you contact customer support.\n\n'
          'We do not collect or store payment card numbers. In-app purchases of virtual coins are processed by '
          'the store you purchased through (such as the Google Play Store), which provides us only the information '
          'needed to credit your account.',
    ),
    LegalSection(
      '3. How we use your information',
      'We use your information to:\n\n'
          '• Create and manage your account and keep your progress saved.\n'
          '• Provide, maintain and improve the Service, including matchmaking, leaderboards and game features.\n'
          '• Respond to your support requests and communicate with you about your account.\n'
          '• Keep the Service secure, prevent fraud, cheating and abuse, and enforce our rules.\n'
          '• Comply with applicable laws and regulations.\n\n'
          'We process your information only for the purposes described here, and for no longer than necessary.',
    ),
    LegalSection(
      '4. Sharing your information',
      'We do not sell your personal information. We share it only in these limited circumstances:\n\n'
          '• With service providers that help us operate the Service (for example hosting and analytics), who are '
          'bound by confidentiality and may use your data only on our behalf.\n'
          '• With law enforcement or other authorities when we are legally required to do so.\n'
          '• In connection with a merger, sale or transfer of assets, where the recipient agrees to protect your '
          'information under the terms of this policy.',
    ),
    LegalSection(
      '5. Data retention and security',
      'We keep your information for as long as your account is active, and for a reasonable period afterwards '
          'where needed to meet legal or operational requirements. When you delete your account, we remove or '
          'anonymise your personal information unless retention is required by law.\n\n'
          'We use technical and organisational measures — including encrypted transmission and restricted access — '
          'to protect your data. No method of transmission is completely secure, but we work to keep your information safe.',
    ),
    LegalSection(
      '6. Your rights and choices',
      'You can access and update your profile at any time in the app. Depending on where you live, you may also '
          'have the right to ask for a copy of your personal information, to correct it, to request its deletion, or '
          'to object to its processing. To exercise these rights, contact us using the details below.',
    ),
    LegalSection(
      '7. Children’s privacy',
      'The Service is not directed to children. We do not knowingly collect personal information from anyone '
          'under the age of 13. If you believe a child has provided us with personal information, contact us and '
          'we will delete it.',
    ),
    LegalSection(
      '8. Changes to this policy',
      'We may update this Privacy Policy from time to time. When we make material changes, we will update the '
          'date below and, where appropriate, notify you in the app. Continued use of the Service after changes '
          'are posted means you accept the updated policy.\n\n'
          'Last updated: 12 September 2026.',
    ),
    LegalSection(
      '9. Contact us',
      'If you have questions about this policy or how your information is handled, contact us at '
          'sheraztech229@gmail.com.',
    ),
  ],
);

final termsDoc = LegalDoc(
  title: 'Terms & community rules',
  sections: [
    LegalSection(
      '1. Acceptance of terms',
      'By downloading, accessing or playing Taash Online, you agree to be bound by these Terms & community rules '
          '("Terms"). If you do not agree, please do not use the Service. These Terms form a contract between you and '
          'SherazTech.',
    ),
    LegalSection(
      '2. Eligibility',
      'You must be at least 13 years old to use the Service, and at least 18 years old (or the age of majority in '
          'your country) to make purchases. If you are under the age of majority, you confirm that a parent or guardian '
          'has reviewed and accepted these Terms on your behalf.',
    ),
    LegalSection(
      '3. Your account',
      'You are responsible for keeping your account details accurate and for protecting your login credentials. '
          'You may not share your account, sell or transfer accounts, or allow another person to play on your behalf. '
          'You are responsible for all activity that happens through your account. Use one account only — multiple '
          'accounts, for example to change your identity or to gain an unfair advantage, are not allowed.',
    ),
    LegalSection(
      '4. Virtual coins and purchases',
      'Virtual coins are in-app items with no real-world money value and no cash redemption. When you open a '
          'round or enter a game, your entry fee is collected using virtual coins. Refunds of in-app purchases are '
          'governed by the store where the purchase was made (for example the Google Play Store) and applicable law. '
          'Virtual coins shown in your balance are provided for your personal entertainment; they cannot be withdrawn, '
          'transferred or converted to real currency, and they have no value outside the Service.',
    ),
    LegalSection(
      '5. Fair play',
      'We want every round to be honest and fun. You agree not to:\n\n'
          '• Use bots, automation or unauthorised third-party software.\n'
          '• Collude with other players to manipulate a game or its outcome.\n'
          '• Exploit bugs, glitches or errors to gain an unfair advantage.\n'
          '• Attempt to read, extract or interfere with game data you are not meant to see.\n\n'
          'We reserve the right to correct game results caused by technical errors and to take action, including '
          'removing virtual coins, suspending or terminating accounts that violate these rules.',
    ),
    LegalSection(
      '6. Conduct',
      'Be respectful. You agree not to post, send or promote anything that is unlawful, abusive, harassing, '
          'defamatory, hateful or sexually explicit, and not to spam, impersonate others, or attempt to disrupt the '
          'Service. Accounts reported for abusive behaviour may be restricted.',
    ),
    LegalSection(
      '7. Intellectual property',
      'The Service — including all graphics, artwork, sounds, text, software and the Taash Online name — is owned '
          'by SherazTech or its licensors and is protected by intellectual property laws. You may not copy, modify, '
          'distribute or create derivative works from any part of the Service without our permission.',
    ),
    LegalSection(
      '8. Disclaimers',
      'The Service is provided "as is" and "as available" for your entertainment. To the maximum extent permitted '
          'by law, we make no warranties about its availability, reliability or fitness for a particular purpose. We '
          'may update, suspend or withdraw the Service, or features within it, at any time.',
    ),
    LegalSection(
      '9. Limitation of liability',
      'To the maximum extent permitted by law, SherazTech will not be liable for indirect, incidental, special or '
          'consequential damages, or for any loss of data, virtual items or profits, arising out of your use of the '
          'Service. Nothing in these Terms limits liability that cannot be limited by law.',
    ),
    LegalSection(
      '10. Termination',
      'We may suspend or terminate your access to the Service, and deactivate your account, if you breach these '
          'Terms or if we are required to do so by law. You may stop using the Service at any time, and you can delete '
          'your account from Settings or by contacting us.',
    ),
    LegalSection(
      '11. Changes to these terms',
      'We may revise these Terms from time to time. Material changes will be reflected by an updated date below and, '
          'where appropriate, a notice in the app. Your continued use of the Service after changes are posted means you '
          'accept the updated Terms.\n\n'
          'Last updated: 12 September 2026.',
    ),
    LegalSection(
      '12. Contact us',
      'Questions about these Terms? Contact us at sheraztech229@gmail.com.',
    ),
  ],
);

final deletionDoc = LegalDoc(
  title: 'Account deletion information',
  sections: [
    LegalSection(
      '1. How to delete your account',
      'You can delete your account directly in the app:\n\n'
          '1. Open the Settings screen from the home tab.\n'
          '2. Scroll to the bottom and tap "Delete account".\n'
          '3. Confirm that you want to delete your account.\n\n'
          'You will be signed out immediately and your account will be scheduled for deletion.'
          'If you run into any problem, you can also request deletion by emailing sheraztech229@gmail.com '
          'from the address linked to your account.',
    ),
    LegalSection(
      '2. What gets deleted',
      'When your account is deleted, the following is removed from the Service:\n\n'
          '• Your profile, display name and email address.\n'
          '• Your virtual-coin balance, avatars and all in-app items.\n'
          '• Your game history, match records and leaderboard entries.\n\n'
          'Deletion is permanent and cannot be undone. You will not be able to sign in to the deleted account again.',
    ),
    LegalSection(
      '3. What may be retained',
      'A small amount of information may be kept for a limited period where we are required to by law or for '
          'legitimate business reasons, such as:\n\n'
          '• Records of purchases, for refund and tax obligations.\n'
          '• Records needed to prevent fraud, cheating or abuse.\n'
          '• Information required by applicable law or legal proceedings.\n\n'
          'Any retained data is stored securely, is used only for those purposes, and is deleted as soon as '
          'those obligations end.',
    ),
    LegalSection(
      '4. How long it takes',
      'Deletion is processed automatically and is usually completed within a few days. In some cases — for '
          'example when a deletion is reviewed for compliance reasons — it can take up to 30 days. We will not '
          'process purchases or wins under an account that has been deleted.',
    ),
    LegalSection(
      '5. Before you delete',
      'Please consider the following before deleting your account:\n\n'
          '• Virtual coins and avatars cannot be transferred to another account and are not refundable.\n'
          '• You will lose access to any pending or in-progress matches.\n'
          '• You will need to create a brand-new account if you want to play again afterwards.',
    ),
    LegalSection(
      '6. Questions',
      'If you have any questions about account deletion, personal data or this information, contact us at '
          'sheraztech229@gmail.com.',
    ),
  ],
);

/// Pushes [doc] as a full in-app page, following the same pattern as the
/// open-source licenses page.
void showLegalDoc(BuildContext context, LegalDoc doc) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => _LegalDocPage(doc)));
}

class _LegalDocPage extends StatelessWidget {
  const _LegalDocPage(this.doc);
  final LegalDoc doc;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(doc.title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        for (final section in doc.sections) ...[
          Text(
            section.heading,
            style: const TextStyle(
              color: T.ochre,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(color: T.white, fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
}
