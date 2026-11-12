import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Manages and broadcasts the global company branding (company name & company logo URL/bytes)
/// so that the side drawer, top bar, and settings remain instantly synchronized across the app
/// with zero network delay, instant frame-0 rendering, and zero loading flicker.
class CompanySettings extends ChangeNotifier {
  static final CompanySettings instance = CompanySettings._internal();
  factory CompanySettings() => instance;
  CompanySettings._internal();

  static const String _nameKey = 'cached_company_name';
  static const String _logoKey = 'cached_company_logo_url';
  static const String _logoBytesKey = 'cached_company_logo_bytes';

  String _companyName = 'Rank First Technologies';
  String? _logoUrl;
  Uint8List? _logoBytes;
  ui.Image? _decodedLogo;
  bool _loaded = false;
  final Set<String> _inFlightFetches = {};

  String get companyName => _companyName;
  String? get logoUrl => _logoUrl;
  Uint8List? get logoBytes => _logoBytes;
  ui.Image? get decodedLogo => _decodedLogo;
  bool get isLoaded => _loaded;

  /// Ensures image bytes are fetched and cached in memory + SharedPreferences immediately.
  Future<void> ensureLogoCached(String url) async {
    if (_logoBytes != null || url.trim().isEmpty) return;
    await _fetchAndCacheLogoBytes(url);
  }

  /// Decodes raw image bytes into an in-memory GPU texture (ui.Image) for zero-latency frame-0 rendering.
  Future<void> _decodeUiImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetHeight: 144, // 36dp @ 4x DPR target
      );
      final frame = await codec.getNextFrame();
      _decodedLogo = frame.image;
      notifyListeners();
    } catch (_) {}
  }

  /// Loads cached values and image bytes from SharedPreferences immediately for zero-flicker instant rendering.
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_nameKey);
      final savedLogo = prefs.getString(_logoKey);
      final savedBytes = prefs.getString(_logoBytesKey);

      if (savedName != null && savedName.trim().isNotEmpty) {
        _companyName = savedName.trim();
      }
      if (savedLogo != null && savedLogo.trim().isNotEmpty) {
        _logoUrl = savedLogo.trim();
      }
      if (savedBytes != null && savedBytes.isNotEmpty) {
        try {
          _logoBytes = base64Decode(savedBytes);
          unawaited(_decodeUiImage(_logoBytes!));
        } catch (_) {}
      }
      _loaded = true;
      notifyListeners();

      if (_logoUrl != null && _logoBytes == null) {
        unawaited(_fetchAndCacheLogoBytes(_logoUrl!));
      }
    } catch (_) {}
  }

  /// Updates current in-memory branding, image bytes and persists to SharedPreferences.
  Future<void> update({
    required String companyName,
    String? logoUrl,
    Uint8List? logoBytes,
  }) async {
    _companyName = companyName.trim();
    _logoUrl = (logoUrl != null && logoUrl.trim().isNotEmpty)
        ? logoUrl.trim()
        : null;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      _logoBytes = logoBytes;
      unawaited(_decodeUiImage(_logoBytes!));
    } else if (_logoUrl == null) {
      _logoBytes = null;
      _decodedLogo = null;
    }
    _loaded = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, _companyName);
      if (_logoUrl != null) {
        await prefs.setString(_logoKey, _logoUrl!);
      } else {
        await prefs.remove(_logoKey);
      }
      if (_logoBytes != null) {
        await prefs.setString(_logoBytesKey, base64Encode(_logoBytes!));
      } else {
        await prefs.remove(_logoBytesKey);
      }
    } catch (_) {}

    if (_logoUrl != null && _logoBytes == null) {
      unawaited(_fetchAndCacheLogoBytes(_logoUrl!));
    }
  }

  /// Pre-fetches and caches image bytes in memory and SharedPreferences for instantaneous display.
  Future<void> _fetchAndCacheLogoBytes(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || _inFlightFetches.contains(cleanUrl)) return;
    _inFlightFetches.add(cleanUrl);

    try {
      final resolved = ApiClient().resolveMediaUrl(cleanUrl) ?? cleanUrl;
      final uri = Uri.parse(resolved);
      final client = http.Client();
      final res = await client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _logoBytes = res.bodyBytes;
        unawaited(_decodeUiImage(res.bodyBytes));
        notifyListeners();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_logoBytesKey, base64Encode(res.bodyBytes));
        } catch (_) {}
      }
    } catch (_) {} finally {
      _inFlightFetches.remove(cleanUrl);
    }
  }

  /// Refreshes company settings from the backend API.
  Future<void> fetchFromApi() async {
    try {
      final response = await ApiClient().get('/settings');
      final dynamic decoded = ApiClient().decodeJson(response);
      if (decoded is Map<String, dynamic> &&
          decoded['settings'] is Map<String, dynamic>) {
        final s = decoded['settings'] as Map<String, dynamic>;
        final name = (s['company_name'] ?? '').toString();
        final logo = s['logo_url']?.toString();
        await update(
          companyName: name.isNotEmpty ? name : _companyName,
          logoUrl: logo,
        );
      }
    } catch (_) {}
  }
}
