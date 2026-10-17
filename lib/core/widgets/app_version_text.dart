import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed build's version as the store knows it, e.g. "1.4.0 (22)":
/// pubspec's build name and build number, read back from the platform so it
/// always matches the binary instead of a string someone forgot to bump.
///
/// Read once and cached. Resolves to null where the platform cannot report it
/// (widget tests without the plugin, for one), and callers then leave the
/// version out rather than show a made-up one.
Future<String?> appVersionLabel() => _versionLabel ??= _readVersionLabel();

Future<String?>? _versionLabel;

Future<String?> _readVersionLabel() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isEmpty) return null;
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
  } catch (_) {
    return null;
  }
}

/// "[prefix][separator][version]", or just [prefix] until (or unless) the
/// version is known.
class AppVersionText extends StatelessWidget {
  const AppVersionText({
    super.key,
    this.prefix = 'TaashOnline',
    this.separator = ' ',
    this.style,
  });

  final String prefix;
  final String separator;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: appVersionLabel(),
    builder: (context, snapshot) {
      final version = snapshot.data;
      return Text(
        version == null ? prefix : '$prefix$separator$version',
        style: style,
      );
    },
  );
}
