import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/audio/audio_system.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/preferences/preferences.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/strings.dart';

const privacyUrl = String.fromEnvironment(Copy.privacyURL);
const termsUrl = String.fromEnvironment(Copy.termsURL);
const deletionUrl = String.fromEnvironment(Copy.accountDELETIONURL);
const supportEmail = String.fromEnvironment(Copy.supportEMAIL);
Future<void> openPolicy(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
    showNotice(context, Copy.thisLinkHasNotBeenConfiguredFor);
    return;
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    showNotice(context, Copy.weCouldNotOpenTheLinkPlease);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.auth,
    required this.preferences,
  });
  final AuthController auth;
  final Preferences preferences;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;
  Future<void> logout() async {
    if (!await confirmAction(
          context,
          title: Copy.leaveForNow,
          message: Copy.youCanSignBackInWheneverYou,
          confirmLabel: Copy.signOut,
        ) ||
        !mounted) {
      return;
    }
    await widget.auth.signOut();
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> delete() async {
    if (!await confirmAction(
          context,
          title: Copy.deleteYourAccount,
          message: Copy.yourTaashOnlineAccountProfileCoinsAvatarOwnership,
          confirmLabel: Copy.deleteAccount,
        ) ||
        !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await widget.auth.deleteAccount();
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    } catch (_) {
      if (mounted) {
        showNotice(context, Copy.weCouldNotConfirmAccountDeletionPlease);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(Copy.settings)),
    body: ListenableBuilder(
      listenable: widget.preferences,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TaashSectionHeader(
            eyebrow: Copy.yourCARDNIGHT,
            title: S.settings,
          ),
          const SizedBox(height: 24),
          TaashPanel(
            child: Row(
              children: [
                TaashAvatar(id: widget.auth.profile?.selectedPfp ?? 0),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.auth.profile?.displayName ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        (widget.auth.profile?.email != null &&
                                widget.auth.profile!.email.isNotEmpty)
                            ? widget.auth.profile!.email
                            : Copy.taashonlineAccount,
                        style: const TextStyle(color: T.muted),
                      ),
                      // A2: Show account creation date.
                      if (widget.auth.profile != null &&
                          widget.auth.profile!.createdAt.year > 1970)
                        Text(
                          'Member since ${DateFormat.yMMMM('en').format(widget.auth.profile!.createdAt.toLocal())}',
                          style: const TextStyle(color: T.muted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(Copy.soundEffects),
            subtitle: const Text(Copy.audioAssetsAreNotAvailableInThis),
            value: widget.preferences.sfx,
            onChanged: (v) {
              widget.preferences.set('sfx', v);
              audio.sfxEnabled = v;
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(Copy.music),
            subtitle: const Text(Copy.yourPreferenceIsSavedForFutureAudio),
            value: widget.preferences.music,
            onChanged: (v) {
              widget.preferences.set('music', v);
              if (v) {
                audio.playBgm();
              } else {
                audio.stopBgm();
              }
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(Copy.hapticFeedback),
            subtitle: const Text('A light touch for selections and actions.'),
            value: widget.preferences.haptics,
            onChanged: (v) => widget.preferences.set('haptics', v),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(Copy.reduceMotion),
            subtitle: const Text(Copy.keepTheFeedbackSimplifyTheMovement),
            value: widget.preferences.reducedMotion,
            onChanged: (v) => widget.preferences.set('reducedMotion', v),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(Copy.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openPolicy(context, privacyUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text(Copy.termsCommunityRules),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openPolicy(context, termsUrl),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_remove_outlined),
            title: const Text(Copy.accountDeletionInformation),
            onTap: () => openPolicy(context, deletionUrl),
          ),
          if (supportEmail.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: const Text(Copy.contactSherazTech),
              subtitle: Text(supportEmail),
              onTap: () => launchUrl(Uri(scheme: 'mailto', path: supportEmail)),
            ),
          const Divider(),
          TaashButton(
            label: Copy.signOut,
            icon: Icons.logout,
            secondary: true,
            onPressed: busy ? null : logout,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: busy ? null : delete,
            child: Text(
              busy ? Copy.deletingAccount : Copy.deleteAccount,
              style: const TextStyle(color: T.danger),
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              Copy.taashonline1001,
              style: TextStyle(color: T.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
