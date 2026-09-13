
import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../theme/taash_theme.dart';

class TaashButton extends StatelessWidget {
  const TaashButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.busy = false,
    this.onDark = false,
    this.compact = false,
    this.fill,
    this.onFill,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary, busy, onDark, compact;

  /// Primary fill for a game-tinted button (e.g. the waiting room's Leave
  /// button). When set, it replaces [onDark]'s fixed ochre background.
  final Color? fill;
  final Color? onFill;
  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (busy || icon != null) const SizedBox(width: 9),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return Semantics(
      button: true,
      child: secondary
          ? OutlinedButton(
              style: onDark
                  ? OutlinedButton.styleFrom(
                      foregroundColor: T.white,
                      disabledForegroundColor: T.mint,
                      backgroundColor: Colors.white.withValues(alpha: .06),
                      side: const BorderSide(color: T.mint),
                      padding: compact ? const EdgeInsets.all(6) : null,
                      minimumSize: compact ? const Size(48, 48) : null,
                      textStyle: compact
                          ? const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    )
                  : null,
              onPressed: busy ? null : onPressed,
              child: content,
            )
          : FilledButton(
              style: onDark || fill != null
                  ? FilledButton.styleFrom(
                      disabledForegroundColor: T.mint,
                      backgroundColor: fill ?? T.ochre,
                      foregroundColor: onFill ?? const Color(0xff2A193A),
                      disabledBackgroundColor: const Color(0xff3B2D58),
                      padding: compact ? const EdgeInsets.all(6) : null,
                      minimumSize: compact ? const Size(48, 48) : null,
                      textStyle: compact
                          ? const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                    )
                  : null,
              onPressed: busy ? null : onPressed,
              child: content,
            ),
    );
  }
}

class TaashPanel extends StatelessWidget {
  const TaashPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = T.surface,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: T.outline.withValues(alpha: .65)),
    ),
    child: child,
  );
}

class TaashEmpty extends StatelessWidget {
  const TaashEmpty({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.style_outlined,
  });
  final String title, message;
  final VoidCallback? onRetry;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(21),
            decoration: const BoxDecoration(
              color: T.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: T.pine),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 22),
            TaashButton(
              label: Copy.tryAgain,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    ),
  );
}

class TaashAvatar extends StatelessWidget {
  const TaashAvatar({super.key, required this.id, this.size = 56});
  final int id;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: Copy.avatar(id + 1),
    image: true,
    child: Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xffFFE194), Color(0xffD88C28)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            offset: const Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: id >= 0 && id <= 14
            ? Image.asset(
                'assets/pfps/$id.png',
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .ceil()
                    .clamp(64, 500),
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person, color: T.pine),
              )
            : const Icon(Icons.person, color: T.pine),
      ),
    ),
  );
}

class TaashCurrencyChip extends StatelessWidget {
  const TaashCurrencyChip({super.key, required this.value, this.xp = false});
  final int value;
  final bool xp;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value ${xp ? 'experience points' : 'virtual coins'}',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: xp ? const Color(0xff193253) : const Color(0xff302C33),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            xp ? Icons.bolt_rounded : Icons.toll_rounded,
            size: 18,
            color: xp ? const Color(0xff69DFFF) : T.ochre,
          ),
          const SizedBox(width: 5),
          AnimatedSwitcher(
            duration: T.standard,
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class TaashSectionHeader extends StatelessWidget {
  const TaashSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });
  final String eyebrow, title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: const TextStyle(
          letterSpacing: 2.2,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: T.coral,
        ),
      ),
      const SizedBox(height: 8),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle!, style: const TextStyle(color: T.muted)),
      ],
    ],
  );
}

Future<V?> showTaashSheet<V>(BuildContext context, Widget child) =>
    showModalBottomSheet<V>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: child,
          ),
        ),
      ),
    );

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

void showNotice(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

class TaashFlag extends StatelessWidget {
  const TaashFlag({super.key, required this.code, this.size = 20});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code.trim().toUpperCase())) {
      return Icon(Icons.public, size: size, color: const Color(0xffB5D3F9));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        'https://flagcdn.com/w40/${code.trim().toLowerCase()}.png',
        width: size * 1.33,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.public, size: size, color: const Color(0xffB5D3F9)),
      ),
    );
  }
}
