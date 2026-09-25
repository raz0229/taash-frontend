import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:taash/core/config/app_config.dart';

enum InGameNewsStatus { idle, loading, ready, unavailable, invalid, failed }

class InGameNews {
  const InGameNews({
    required this.headline,
    required this.subtitle,
    required this.image,
  });

  final String headline;
  final String subtitle;
  final Uri image;

  factory InGameNews.fromJson(Object? value, {required bool allowInsecure}) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('News must be a JSON object.');
    }
    final headline = _requiredText(value, 'headline', maxLength: 160);
    final subtitle = _requiredText(value, 'subtitle', maxLength: 600);
    final imageValue = value['image'];
    if (imageValue is! String || imageValue.trim().isEmpty) {
      throw const FormatException('News image must be a URL.');
    }
    final image = Uri.tryParse(imageValue.trim());
    if (image == null ||
        !image.hasAuthority ||
        image.userInfo.isNotEmpty ||
        image.fragment.isNotEmpty ||
        (image.scheme != 'https' &&
            !(allowInsecure && image.scheme == 'http'))) {
      throw const FormatException('News image URL is invalid.');
    }
    return InGameNews(headline: headline, subtitle: subtitle, image: image);
  }

  static String _requiredText(
    Map<String, dynamic> value,
    String key, {
    required int maxLength,
  }) {
    final text = value[key];
    if (text is! String ||
        text.trim().isEmpty ||
        text.trim().length > maxLength) {
      throw FormatException('News $key is invalid.');
    }
    return text.trim();
  }
}

class InGameNewsService extends ChangeNotifier {
  InGameNewsService({
    required AppConfig config,
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _config = config,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final AppConfig _config;
  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  InGameNewsStatus _status = InGameNewsStatus.idle;
  InGameNews? _news;
  Future<void>? _inFlight;
  bool _consumed = false;
  bool _disposed = false;

  InGameNewsStatus get status => _status;
  InGameNews? get news => _news;
  bool get consumed => _consumed;

  Future<void> load() {
    if (_disposed) return Future.value();
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final uri = _config.inGameNewsUri;
    if (_config.mock || uri == null) {
      _status = InGameNewsStatus.unavailable;
      return Future.value();
    }

    _status = InGameNewsStatus.loading;
    notifyListeners();
    final request = _fetch(uri);
    _inFlight = request;
    return request;
  }

  void consume() {
    _consumed = true;
  }

  Future<void> _fetch(Uri uri) async {
    InGameNews? loadedNews;
    var nextStatus = InGameNewsStatus.failed;
    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache, no-store, max-age=0',
              'Pragma': 'no-cache',
            },
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw http.ClientException(
          'News request failed with ${response.statusCode}.',
          uri,
        );
      }
      if (response.bodyBytes.lengthInBytes > 64 * 1024) {
        throw const FormatException('News response is too large.');
      }
      loadedNews = InGameNews.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
        allowInsecure: _config.allowInsecure,
      );
      nextStatus = InGameNewsStatus.ready;
    } on FormatException {
      nextStatus = InGameNewsStatus.invalid;
    } catch (_) {
      nextStatus = InGameNewsStatus.failed;
    }
    if (_disposed) return;
    _news = loadedNews;
    _status = nextStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
