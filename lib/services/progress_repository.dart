import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar.dart';

class SiteProgress {
  const SiteProgress({
    this.found = const {},
    this.fogBytes,
    this.unseen = const [],
  });
  final Map<String, DateTime> found; // item id -> UTC
  final Uint8List? fogBytes;
  final List<String> unseen;

  SiteProgress copyWith({
    Map<String, DateTime>? found,
    Uint8List? fogBytes,
    List<String>? unseen,
  }) => SiteProgress(
    found: found ?? this.found,
    fogBytes: fogBytes ?? this.fogBytes,
    unseen: unseen ?? this.unseen,
  );
}

class ProgressRepository {
  ProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _name = 'player.name';
  static const _avatar = 'player.avatar';
  static const _active = 'site.active';
  static const _debug = 'debug.enabled';
  static const _exploring = 'exploring';
  static String _found(String s) => 'progress.$s.found';
  static String _fog(String s) => 'progress.$s.fog';
  static String _unseen(String s) => 'progress.$s.unseen';

  String? get playerName => _prefs.getString(_name);
  Future<void> setPlayerName(String name) => _prefs.setString(_name, name);

  bool get hasAvatar => _prefs.containsKey(_avatar);

  // A non-string value under the key makes getString throw.
  Avatar get avatar {
    try {
      return Avatar.fromName(_prefs.getString(_avatar));
    } catch (_) {
      return Avatar.fallback;
    }
  }

  Future<void> setAvatar(Avatar a) => _prefs.setString(_avatar, a.name);

  String? get activeSiteId => _prefs.getString(_active);
  Future<void> setActiveSiteId(String id) => _prefs.setString(_active, id);

  bool get debugEnabled => _prefs.getBool(_debug) ?? false;
  Future<void> setDebugEnabled(bool v) => _prefs.setBool(_debug, v);

  bool get exploring => _prefs.getBool(_exploring) ?? false;
  Future<void> setExploring(bool v) => _prefs.setBool(_exploring, v);

  // Each part is decoded on its own so one corrupt entry loses only itself.
  SiteProgress load(String siteId) => SiteProgress(
    found: _loadFound(siteId),
    fogBytes: _loadFog(siteId),
    unseen: _loadUnseen(siteId),
  );

  Map<String, DateTime> _loadFound(String siteId) {
    try {
      final raw = _prefs.getString(_found(siteId));
      if (raw == null) return const {};
      final m = (jsonDecode(raw) as Map).cast<String, String>();
      return {
        for (final e in m.entries) e.key: DateTime.parse(e.value).toUtc(),
      };
    } catch (_) {
      return const {};
    }
  }

  Uint8List? _loadFog(String siteId) {
    try {
      final raw = _prefs.getString(_fog(siteId));
      return raw == null ? null : base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  List<String> _loadUnseen(String siteId) {
    try {
      return _prefs.getStringList(_unseen(siteId)) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveFound(String siteId, Map<String, DateTime> found) =>
      _prefs.setString(
        _found(siteId),
        jsonEncode({
          for (final e in found.entries)
            e.key: e.value.toUtc().toIso8601String(),
        }),
      );

  Future<void> saveFog(String siteId, Uint8List bytes) =>
      _prefs.setString(_fog(siteId), base64Encode(bytes));

  Future<void> saveUnseen(String siteId, List<String> unseen) =>
      _prefs.setStringList(_unseen(siteId), unseen);

  Future<void> reset(String siteId) async {
    await _prefs.remove(_found(siteId));
    await _prefs.remove(_fog(siteId));
    await _prefs.remove(_unseen(siteId));
  }
}
