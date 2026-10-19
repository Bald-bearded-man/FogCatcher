// Text edits on pubspec.yaml and assets/sites/index.json shared by new_site and apply_pack.
import 'dart:convert';

const _fixedAssetsHead = [
  'assets/brand/',
  'assets/fonts/',
  'assets/tiles/',
  'assets/sites/',
];
const _fixedAssetsTail = ['assets/items/'];

/// Replaces the `flutter.assets` list: fixed dirs plus one entry per site, since asset dirs are not recursive.
String withSiteAssets(String pubspec, List<String> siteIds) {
  final lines = const LineSplitter().convert(pubspec);
  final flutter = lines.indexOf('flutter:');
  if (flutter < 0) {
    throw const FormatException('pubspec has no flutter: section');
  }
  final start = lines.indexOf('  assets:', flutter);
  if (start < 0) throw const FormatException('pubspec has no flutter.assets');
  var end = start + 1;
  while (end < lines.length && lines[end].startsWith('    - ')) {
    end++;
  }
  lines.replaceRange(start + 1, end, [
    for (final a in [
      ..._fixedAssetsHead,
      for (final id in siteIds) 'assets/sites/$id/',
      ..._fixedAssetsTail,
    ])
      '    - $a',
  ]);
  return '${lines.join('\n')}\n';
}

/// Sets the launcher-icon background and splash colours to [hex] (`#RRGGBB`).
String withBrandColor(String pubspec, String hex) => pubspec.replaceAllMapped(
  RegExp(
    r'^(\s*(?:adaptive_icon_background|color): )"#[0-9A-Fa-f]{6}"$',
    multiLine: true,
  ),
  (m) => '${m[1]}"${hex.toUpperCase()}"',
);

/// Site ids listed in index.json.
List<String> siteIds(String indexJson) =>
    ((jsonDecode(indexJson) as Map<String, dynamic>)['sites'] as List<dynamic>)
        .cast<String>();

/// index.json with [id] appended unless already listed.
String withSite(String indexJson, String id) {
  final ids = siteIds(indexJson);
  return encodeIndex([...ids, if (!ids.contains(id)) id]);
}

String encodeIndex(List<String> ids) =>
    '${const JsonEncoder.withIndent('  ').convert({'sites': ids})}\n';

const _targetApi = {
  'android:forceDarkAllowed': 'q',
  'android:windowLayoutInDisplayCutoutMode': 'o_mr1',
};

/// flutter_native_splash drops the API guards that keep lintRelease green at minSdk 24.
String guardSplashStyles(String xml) {
  for (final MapEntry(key: name, value: api) in _targetApi.entries) {
    xml = xml.replaceAll(
      '<item name="$name">',
      '<item name="$name" tools:targetApi="$api">',
    );
  }
  return xml;
}
