import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const osmLicense =
    'Map data © OpenStreetMap contributors, available under the Open '
    'Database License (ODbL) 1.0. https://www.openstreetmap.org/copyright';

/// Ships with the item photos, so a pack's own items/ folder replaces it.
const itemCreditsAsset = 'assets/items/CREDITS.md';

/// Bundled fonts, tiles, map data and item photos, shown on the Licenses page.
void registerAssetLicenses(AssetBundle bundle) {
  LicenseRegistry.addLicense(() async* {
    for (final f in ['PressStart2P', 'VT323']) {
      yield LicenseEntryWithLineBreaks([
        f,
      ], await bundle.loadString('assets/fonts/OFL-$f.txt'));
    }
    yield LicenseEntryWithLineBreaks([
      'Kenney',
    ], await bundle.loadString('assets/tiles/LICENSE-kenney.txt'));
    yield const LicenseEntryWithLineBreaks(['OpenStreetMap'], osmLicense);
    for (final c in creditEntries(
      await _loadOptional(bundle, itemCreditsAsset),
    )) {
      yield LicenseEntryWithLineBreaks(['Item photos'], c);
    }
  });
}

// Packs with their own photos may ship no credits file.
Future<String> _loadOptional(AssetBundle bundle, String key) async {
  try {
    return await bundle.loadString(key);
  } catch (_) {
    return '';
  }
}

/// One `Header: value` paragraph per cell, per row of the Markdown table in [md].
List<String> creditEntries(String md) {
  final rows = [
    for (final line in md.split('\n'))
      if (line.trim().startsWith('|')) _cells(line),
  ];
  if (rows.isEmpty) return const [];
  final header = rows.first;
  final separator = RegExp(r'^:?-+:?$');
  return [
    for (final row in rows.skip(1))
      if (!row.every(separator.hasMatch))
        [
          for (var i = 0; i < row.length && i < header.length; i++)
            '${header[i]}: ${row[i]}',
        ].join('\n\n'),
  ];
}

final _link = RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)');

List<String> _cells(String line) {
  final t = line.trim();
  final inner = t.substring(1, t.endsWith('|') ? t.length - 1 : t.length);
  return [
    for (final c in inner.split('|'))
      c.trim().replaceAllMapped(_link, (m) => '${m[1]} (${m[2]})'),
  ];
}
