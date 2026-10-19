import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fogcatcher/config/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Licenses page lists the fonts, Kenney tiles and OSM data', () async {
    registerAssetLicenses(rootBundle);
    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((e) => e.packages).toSet();
    expect(
      packages,
      containsAll(['PressStart2P', 'VT323', 'Kenney', 'OpenStreetMap']),
    );
    final osm = entries.firstWhere((e) => e.packages.contains('OpenStreetMap'));
    final text = osm.paragraphs.map((p) => p.text).join();
    expect(text, contains('© OpenStreetMap contributors'));
    expect(text, contains('ODbL'));
  });

  test('Licenses page lists one entry per bundled photo credit', () async {
    final file = File(itemCreditsAsset);
    final rows = file.existsSync()
        ? creditEntries(file.readAsStringSync())
        : const <String>[];
    registerAssetLicenses(rootBundle);
    final photos = (await LicenseRegistry.licenses.toList())
        .where((e) => e.packages.contains('Item photos'))
        .map((e) => e.paragraphs.map((p) => p.text).join('\n\n'))
        .toSet();
    expect(photos, rows.toSet());
  });

  group('creditEntries', () {
    test('turns each table row into header-labelled paragraphs', () {
      const md =
          '# Credits\n\nIntro | not a row.\n\n'
          '| File | Author | Licence |\n'
          '|---|:---:|---|\n'
          '| a.webp | Ann | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |\n'
          '| b.webp | Bob | Public domain |\n';
      expect(creditEntries(md), [
        'File: a.webp\n\nAuthor: Ann\n\n'
            'Licence: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0)',
        'File: b.webp\n\nAuthor: Bob\n\nLicence: Public domain',
      ]);
    });

    test('no table, no entries', () {
      expect(creditEntries(''), isEmpty);
      expect(creditEntries('# Credits\n\nNone yet.\n'), isEmpty);
    });
  });
}
