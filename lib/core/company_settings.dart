import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
  static const String _legacyLogoBytesKey = 'cached_company_logo_bytes';
  static const String _logoCacheFileName = 'company_logo_cache.bin';

  String _companyName = 'Rank First Technologies';
  String? _logoUrl;
  Uint8List? _logoBytes;
  ui.Image? _decodedLogo;
  bool _loaded = false;
  Future<void>? _inFlightLoad;
  Future<void>? _inFlightFetch;
  final Set<String> _inFlightFetches = {};

  @visibleForTesting
  Future<Directory> Function()? cacheDirectoryProvider;

  String get companyName => _companyName;
  String? get logoUrl => _logoUrl;
  Uint8List? get logoBytes => _logoBytes;
  ui.Image? get decodedLogo => _decodedLogo;
  bool get isLoaded => _loaded;

  @visibleForTesting
  void resetForTesting() {
    _companyName = 'Rank First Technologies';
    _logoUrl = null;
    _logoBytes = null;
    _decodedLogo?.dispose();
    _decodedLogo = null;
    _loaded = false;
    _inFlightLoad = null;
    _inFlightFetch = null;
    _inFlightFetches.clear();
  }

  Future<File?> _getLogoCacheFile() async {
    if (kIsWeb) return null;
    try {
      final dir = cacheDirectoryProvider != null
          ? await cacheDirectoryProvider!()
          : await getApplicationSupportDirectory();
      return File('${dir.path}/$_logoCacheFileName');
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLogoBytesToFile(Uint8List bytes) async {
    try {
      final file = await _getLogoCacheFile();
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  Future<Uint8List?> _readLogoBytesFromFile() async {
    try {
      final file = await _getLogoCacheFile();
      if (file == null || !await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteLogoCacheFile() async {
    try {
      final file = await _getLogoCacheFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Ensures image bytes are fetched and cached in memory + disk immediately.
  Future<void> ensureLogoCached(String url) async {
    if (_logoBytes != null || url.trim().isEmpty) return;
    await _fetchAndCacheLogoBytes(url);
  }

  /// Decodes raw image bytes into an in-memory GPU texture (ui.Image) for zero-latency rendering.
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

  /// Loads cached values and image bytes from SharedPreferences + binary file cache.
  Future<void> loadFromPrefs() {
    return _inFlightLoad ??= _performLoadFromPrefs().whenComplete(() {
      _inFlightLoad = null;
    });
  }

  Future<void> _performLoadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_nameKey);
      final savedLogo = prefs.getString(_logoKey);
      final legacySavedBytes = prefs.getString(_legacyLogoBytesKey);

      if (savedName != null && savedName.trim().isNotEmpty) {
        _companyName = savedName.trim();
      }
      if (savedLogo != null && savedLogo.trim().isNotEmpty) {
        _logoUrl = savedLogo.trim();
      } else {
        _logoUrl = null;
      }

      if (legacySavedBytes != null && legacySavedBytes.isNotEmpty) {
        // Immediately purge legacy multi-hundred-KB Base64 blob from SharedPreferences
        // so future cold starts avoid parsing oversized XML on the main thread.
        await prefs.remove(_legacyLogoBytesKey);
        try {
          final decoded = await Isolate.run(() => base64Decode(legacySavedBytes));
          if (decoded.isNotEmpty) {
            _logoBytes = decoded;
            unawaited(_writeLogoBytesToFile(decoded));
            unawaited(_decodeUiImage(decoded));
          }
        } catch (_) {}
      } else if (_logoUrl != null) {
        final fileBytes = await _readLogoBytesFromFile();
        if (fileBytes != null && fileBytes.isNotEmpty) {
          _logoBytes = fileBytes;
          unawaited(_decodeUiImage(fileBytes));
        }
      }

      _loaded = true;
      notifyListeners();

      if (_logoUrl != null && _logoBytes == null) {
        unawaited(_fetchAndCacheLogoBytes(_logoUrl!));
      }
    } catch (_) {}
  }

  /// Updates current in-memory branding, image bytes and persists to disk.
  Future<void> update({
    required String companyName,
    String? logoUrl,
    Uint8List? logoBytes,
  }) async {
    final normalizedName = companyName.trim();
    final normalizedUrl = (logoUrl != null && logoUrl.trim().isNotEmpty)
        ? logoUrl.trim()
        : null;

    final nameChanged = normalizedName != _companyName;
    final urlChanged = normalizedUrl != _logoUrl;

    _companyName = normalizedName;
    _logoUrl = normalizedUrl;

    if (logoBytes != null && logoBytes.isNotEmpty) {
      _logoBytes = logoBytes;
      unawaited(_decodeUiImage(_logoBytes!));
      unawaited(_writeLogoBytesToFile(_logoBytes!));
    } else if (_logoUrl == null || urlChanged) {
      _logoBytes = null;
      _decodedLogo = null;
      unawaited(_deleteLogoCacheFile());
    }

    _loaded = true;
    notifyListeners();

    if (nameChanged || urlChanged) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_nameKey, _companyName);
        if (_logoUrl != null) {
          await prefs.setString(_logoKey, _logoUrl!);
        } else {
          await prefs.remove(_logoKey);
        }
      } catch (_) {}
    }

    if (_logoUrl != null && _logoBytes == null) {
      unawaited(_fetchAndCacheLogoBytes(_logoUrl!));
    }
  }

  /// Pre-fetches and caches image bytes in memory and binary file cache.
  Future<void> _fetchAndCacheLogoBytes(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || _inFlightFetches.contains(cleanUrl)) return;
    _inFlightFetches.add(cleanUrl);

    final client = http.Client();
    try {
      final resolved = ApiClient().resolveMediaUrl(cleanUrl) ?? cleanUrl;
      final uri = Uri.parse(resolved);
      final res = await client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _logoBytes = res.bodyBytes;
        unawaited(_decodeUiImage(res.bodyBytes));
        unawaited(_writeLogoBytesToFile(res.bodyBytes));
        notifyListeners();
      }
    } catch (_) {} finally {
      client.close();
      _inFlightFetches.remove(cleanUrl);
    }
  }

  /// Refreshes company settings from the backend API (single-flight).
  Future<void> fetchFromApi() {
    return _inFlightFetch ??= _performFetchFromApi().whenComplete(() {
      _inFlightFetch = null;
    });
  }

  Future<void> _performFetchFromApi() async {
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
