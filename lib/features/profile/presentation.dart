import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String displayNumber(int value) =>
    NumberFormat.decimalPattern('en').format(value);

class CountryLabels {
  CountryLabels(this.names);
  final Map<String, String> names;
  static CountryLabels? _cached;
  static Future<CountryLabels> load() async {
    if (_cached != null) return _cached!;
    final data =
        jsonDecode(
              await rootBundle.loadString('assets/catalogs/countries.json'),
            )
            as List;
    return _cached = CountryLabels(
      Map.unmodifiable({
        for (final row in data) row['code'] as String: row['name'] as String,
      }),
    );
  }

  String name(String? code) {
    final normalized = code?.trim().toUpperCase() ?? '';
    return names[normalized] ?? 'Global';
  }
}
