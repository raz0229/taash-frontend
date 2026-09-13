import 'package:taash/l10n/copy.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/strings.dart';
import 'country_selector.dart';
import 'google_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth, required this.onLearn});
  final AuthController auth;
  final VoidCallback onLearn;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool register = false, reset = false, hidden = true, busy = false;
  bool emailVerifyRequired = false;
  Timer? _verifyTimer;
  bool _polling = false;
  String? message;
  Map<String, dynamic>? country;
  @override
  void dispose() {
    _verifyTimer?.cancel();
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (register && country == null) {
      setState(() => message = Copy.chooseYourCountryToContinue);
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (reset) {
        await widget.auth.forgotPassword(email.text);
        if (mounted) setState(() => message = S.resetSent);
      } else if (register) {
        await widget.auth.register(
          email: email.text,
          password: password.text,
          displayName: name.text.trim(),
          country: country!['code'],
        );
      } else {
        await widget.auth.signIn(email.text, password.text);
      }
    } on AppFailure catch (e) {
      if (mounted) {
        if (e.code == 'email_verification_required' ||
            e.code == 'email_not_verified') {
          setState(() {
            emailVerifyRequired = true;
            message = null;
          });
          _startVerifyPolling();
        } else {
          setState(() => message = e.message);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = Copy.weCouldNotConnectPleaseTryAgain);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// The final step of registration: the account's email must be verified
  /// before the first sign-in. This screen asks the player to confirm they've
  /// tapped the link, then signs them in.
  Future<void> verifyContinue() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.auth.signIn(email.text, password.text);
      _stopVerifyPolling();
    } on AppFailure catch (e) {
      if (!mounted) return;
      // The auto-verify poll can briefly overlap this tap; retry once rather
      // than surfacing "sign-in is already in progress".
      if (e.code == 'busy') {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        try {
          await widget.auth.signIn(email.text, password.text);
          _stopVerifyPolling();
          return;
        } on AppFailure catch (retryFailure) {
          if (mounted) setState(() => message = retryFailure.message);
          return;
        }
      }
      setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => message = Copy.weCouldNotConnectPleaseTryAgain);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.auth.resendVerificationEmail(email.text, password.text);
      if (mounted) setState(() => message = S.verificationEmailSent);
    } on AppFailure catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => message = Copy.weCouldNotConnectPleaseTryAgain);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Polls the server so the player is signed in the moment their email
  /// becomes verified — no need to tap "I've verified · continue".
  void _startVerifyPolling() {
    _verifyTimer?.cancel();
    _verifyTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollVerification(),
    );
    _pollVerification();
  }

  void _stopVerifyPolling() {
    _verifyTimer?.cancel();
    _verifyTimer = null;
  }

  Future<void> _pollVerification() async {
    if (_polling || !mounted || busy || !emailVerifyRequired) return;
    _polling = true;
    try {
      await widget.auth.signIn(email.text, password.text);
      _stopVerifyPolling();
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (e.code == 'email_not_verified' ||
          e.isOffline ||
          e.code == 'timeout' ||
          e.code == 'upstream_timeout' ||
          e.code == 'rate_limited') {
        return; // still waiting; try again on the next tick
      }
      _stopVerifyPolling();
      setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        _stopVerifyPolling();
        setState(() => message = Copy.weCouldNotConnectPleaseTryAgain);
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> googleSignIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      GoogleProfilePrompt? prompt;
      if (register) {
        if (country == null) {
          setState(() => message = Copy.chooseYourCountryToContinue);
          return;
        }
        final nameValue = name.text.trim();
        if (nameValue.isEmpty ||
            nameValue.length > 25 ||
            !RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(nameValue)) {
          setState(() => message = S.invalidName);
          return;
        }
        prompt = await widget.auth.signInWithGoogle(
          displayName: nameValue,
          country: country!['code'],
        );
      } else {
        prompt = await widget.auth.signInWithGoogle();
      }
      if (prompt != null) {
        final profile = await _promptGoogleProfile(prompt);
        if (profile != null) {
          await widget.auth.signInWithGoogle(
            displayName: profile.name,
            country: profile.country,
          );
        }
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => message = e.message);
    } on GoogleAuthFailure catch (e) {
      if (mounted) {
        setState(() => message = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = Copy.weCouldNotConnectPleaseTryAgain);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Collects the display name and country a brand-new Google player still
  /// needs. Returns null when the user backs out.
  Future<({String name, String country})?> _promptGoogleProfile(
    GoogleProfilePrompt prompt,
  ) async {
    final result = await showModalBottomSheet<({String name, String country})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      builder: (_) => _GoogleProfileSheet(
        email: prompt.email,
        displayName: prompt.displayName,
      ),
    );
    return result;
  }

  /// Sign-up checkpoint: the account exists but the server won't hand out a
  /// session until the email link is tapped. Google and legacy sign-ins never
  /// reach this screen.
  Widget _verificationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.mark_email_read_outlined, size: 64, color: T.mint),
        const SizedBox(height: 18),
        Text(
          S.verifyYourEmail,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          Copy.weSentAVerificationLinkTo(email.text.trim()),
          textAlign: TextAlign.center,
          style: const TextStyle(color: T.muted, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          S.autoSignInAfterVerification,
          textAlign: TextAlign.center,
          style: const TextStyle(color: T.muted, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 26),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Semantics(
              liveRegion: true,
              child: TaashPanel(
                color: T.ochre.withValues(alpha: .18),
                padding: const EdgeInsets.all(14),
                child: Text(message!),
              ),
            ),
          ),
        TaashButton(
          label: S.iVeVerifiedContinue,
          onPressed: verifyContinue,
          busy: busy,
          icon: Icons.arrow_forward_rounded,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: busy ? null : resend,
          child: Text(Copy.resendEmail),
        ),
        TextButton(
          onPressed: busy
              ? null
              : () {
                  _stopVerifyPolling();
                  setState(() {
                    emailVerifyRequired = false;
                    message = null;
                  });
                },
          child: Text(Copy.useADifferentAccount),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: AutofillGroup(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/brand/icon.png',
                            width: 56,
                            height: 56,
                            cacheWidth: 168,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              S.appName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.7,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: Copy.learnTheGames,
                          onPressed: widget.onLearn,
                          icon: const Icon(Icons.auto_stories_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      reset
                          ? Copy.backToTheRoom
                          : register
                          ? Copy.thereSASeatWithYourName
                          : 'Your Desi card games.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reset ? Copy.weLlEmailYouALinkTo : S.intro,
                      style: const TextStyle(color: T.muted, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    if (emailVerifyRequired)
                      _verificationPanel()
                    else ...[
                      if (!reset)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: T.outline.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              for (final (value, label) in [
                                (false, Copy.signIn),
                                (true, Copy.register),
                              ])
                                Expanded(
                                  child: GestureDetector(
                                    onTap: busy
                                        ? null
                                        : () => setState(() {
                                            register = value;
                                            message = null;
                                          }),
                                    child: AnimatedContainer(
                                      duration: T.micro,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        color: register == value
                                            ? T.surface
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: register == value
                                              ? T.ink
                                              : T.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (register && !reset) ...[
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: S.displayName,
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          maxLength: 25,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[<>]')),
                            // A13: Only allow ASCII letters, numbers, and spaces.
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9 ]'),
                            ),
                          ],
                          validator: (v) =>
                              v == null ||
                                  v.trim().isEmpty ||
                                  v.trim().length > 25 ||
                                  !RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(v.trim())
                              ? S.invalidName
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: S.email,
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (v) =>
                            v == null ||
                                !RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(v.trim())
                            ? S.invalidEmail
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (!reset) ...[
                        TextFormField(
                          controller: password,
                          obscureText: hidden,
                          autofillHints: [
                            register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: S.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: hidden
                                  ? Copy.showPassword
                                  : Copy.hidePassword,
                              onPressed: () => setState(() => hidden = !hidden),
                              icon: Icon(
                                hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? S.invalidPassword
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (register && !reset) ...[
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final result =
                                      await Navigator.push<
                                        Map<String, dynamic>
                                      >(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CountrySelector(),
                                        ),
                                      );
                                  if (result != null && mounted) {
                                    setState(() => country = result);
                                  }
                                },
                          child: Row(
                            children: [
                              country == null
                                  ? const Icon(Icons.public, size: 20)
                                  : TaashFlag(code: country!['code']),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  country == null
                                      ? Copy.chooseYourCountry
                                      : '${country!['name']} · ${country!['code']}',
                                ),
                              ),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!reset) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: T.outline)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                Copy.or,
                                style: TextStyle(
                                  color: T.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: T.outline)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : googleSignIn,
                            icon: const GoogleLogo(),
                            label: const Text(Copy.continueWithGoogle),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Semantics(
                            liveRegion: true,
                            child: TaashPanel(
                              color: T.ochre.withValues(alpha: .18),
                              padding: const EdgeInsets.all(14),
                              child: Text(message!),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: TaashButton(
                          label: reset
                              ? S.reset
                              : register
                              ? S.register
                              : S.signIn,
                          onPressed: submit,
                          busy: busy,
                          icon: reset
                              ? Icons.mail_outline
                              : Icons.arrow_forward_rounded,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  reset = !reset;
                                  message = null;
                                }),
                          child: Text(reset ? Copy.backToSignIn : S.forgot),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_outline, size: 15, color: T.coral),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            S.tagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: T.muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _GoogleProfileSheet extends StatefulWidget {
  const _GoogleProfileSheet({required this.email, required this.displayName});
  final String email;
  final String displayName;
  @override
  State<_GoogleProfileSheet> createState() => _GoogleProfileSheetState();
}

class _GoogleProfileSheetState extends State<_GoogleProfileSheet> {
  final formKey = GlobalKey<FormState>();
  late final nameCtrl = TextEditingController(text: widget.displayName);
  String? selectedCountryCode;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      0,
      24,
      MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Copy.almostThere, style: const TextStyle(color: T.muted)),
          const SizedBox(height: 8),
          Text(Copy.finishYourSeat, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          TextFormField(
            controller: nameCtrl,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
              LengthLimitingTextInputFormatter(25),
            ],
            decoration: const InputDecoration(hintText: Copy.nameHint),
            validator: (v) => v == null || v.trim().isEmpty
                ? Copy.enterYourName
                : v.trim().length > 25
                ? Copy.max25Chars
                : null,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(builder: (_) => const CountrySelector()),
              );
              if (result != null && mounted) {
                setState(() => selectedCountryCode = result['code']);
              }
            },
            child: Row(
              children: [
                selectedCountryCode == null
                    ? const Icon(Icons.public, size: 20)
                    : TaashFlag(code: selectedCountryCode!),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedCountryCode == null
                        ? Copy.chooseYourCountry
                        : selectedCountryCode!,
                  ),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TaashButton(
              label: S.register,
              busy: false,
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                if (selectedCountryCode == null) return;
                Navigator.of(context).pop((
                  name: nameCtrl.text.trim(),
                  country: selectedCountryCode!,
                ));
              },
            ),
          ),
        ],
      ),
    ),
  );
}
