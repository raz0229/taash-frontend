import 'package:taash/l10n/copy.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/taash_theme.dart';

import '../../core/widgets/taash_widgets.dart';

class CountrySelector extends StatefulWidget {
  const CountrySelector({super.key});
  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  List<Map<String, dynamic>>? countries;
  String query = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        jsonDecode(
              await rootBundle.loadString('assets/catalogs/countries.json'),
            )
            as List;
    if (mounted) setState(() => countries = data.cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = countries
        ?.where(
          (c) => '${c['name']} ${c['code']}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.chooseYourCountry)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: Copy.searchNameOrCountryCode,
              ),
            ),
          ),
          Expanded(
            child: filtered == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return ListTile(
                        minVerticalPadding: 12,
                        leading: TaashFlag(code: c['code'], size: 28),
                        title: Text(c['name']),
                        trailing: Text(
                          c['code'],
                          style: const TextStyle(color: T.muted),
                        ),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
