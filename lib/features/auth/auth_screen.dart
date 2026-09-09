import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/strings.dart';
import 'country_selector.dart';

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
  String? message;
  Map<String, dynamic>? country;
  @override
  void dispose() {
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
      if (mounted) setState(() => message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => message = Copy.weCouldNotConnectPleaseTryAgain);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
                          : 'Your next card night.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reset ? Copy.weLlEmailYouALinkTo : S.intro,
                      style: const TextStyle(color: T.muted, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
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
                                    await Navigator.push<Map<String, dynamic>>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CountrySelector(),
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
