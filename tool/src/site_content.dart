// Pure helpers behind new_site.dart: site.json, the photo catalogue and items.json.
import 'dart:convert';
import 'dart:math' as math;

import 'package:fogcatcher/game/geo.dart';
import 'package:fogcatcher/models/geo_point.dart';

const defaultItemText = 'A photo recovered from the fog.';
const photoExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};

final _siteId = RegExp(r'^[a-z][a-z0-9_]*$');

bool validSiteId(String id) => _siteId.hasMatch(id);

const _pretty = JsonEncoder.withIndent('  ');

double _round(double v) => (v * 1e7).round() / 1e7;

/// site.json for a circle site; bounds are the circle's box plus a small margin.
String siteJson({
  required String id,
  required String name,
  required GeoPoint center,
  required double radiusMeters,
  String? boundary,
}) {
  final reach = radiusMeters + 10;
  final dLat = reach / earthRadiusMeters * 180 / math.pi;
  final dLng = dLat / math.cos(center.lat * math.pi / 180);
  return '${_pretty.convert({
    'id': id,
    'name': name,
    'center': {'lat': _round(center.lat), 'lng': _round(center.lng)},
    'radiusMeters': radiusMeters,
    'bounds': {'south': _round(center.lat - dLat), 'west': _round(center.lng - dLng), 'north': _round(center.lat + dLat), 'east': _round(center.lng + dLng)},
    'boundary': ?boundary,
  })}\n';
}

class Photo {
  const Photo({
    required this.file,
    required this.slug,
    required this.title,
    required this.text,
  });
  final String file; // basename in the photos dir
  final String slug;
  final String title;
  final String text;
}

String _stem(String file) {
  final dot = file.lastIndexOf('.');
  return dot > 0 ? file.substring(0, dot) : file;
}

/// `01_Kite Lawn.png` → `01-kite-lawn`.
String slugOf(String file) => _stem(file)
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// `01_kite_lawn.png` → `Kite Lawn`; a leading number only orders the files.
String titleOf(String file) {
  final words = _stem(file)
      .replaceFirst(RegExp(r'^\d+[-_ ]+(?=\D)'), '')
      .split(RegExp(r'[-_ ]+'))
      .where((w) => w.isNotEmpty);
  return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

/// RFC 4180-ish: commas, double quotes with `""` escapes, CRLF or LF rows.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  row.add(field.toString());
  if (row.any((f) => f.isNotEmpty)) rows.add(row);
  return rows;
}

/// Captioned photos in CSV order, then the rest by filename; titles fall back to the filename.
List<Photo> buildCatalogue(List<String> files, {String? csv}) {
  final captions = <String, ({String title, String text})>{};
  if (csv != null) {
    final rows = parseCsv(csv);
    if (rows.isEmpty || rows.first.join(',') != 'file,title,text') {
      throw const FormatException(
        'captions CSV must start with file,title,text',
      );
    }
    for (final r in rows.skip(1)) {
      if (r.length != 3) {
        throw FormatException(
          'captions CSV row needs 3 fields: ${r.join(',')}',
        );
      }
      if (!files.contains(r[0])) {
        throw FormatException('captions CSV names a missing photo: ${r[0]}');
      }
      captions[r[0]] = (title: r[1].trim(), text: r[2].trim());
    }
  }
  final ordered = [
    ...captions.keys,
    ...([...files]..sort()).where((f) => !captions.containsKey(f)),
  ];
  final slugs = <String>{};
  return [
    for (final f in ordered)
      Photo(
        file: f,
        slug: slugs.add(slugOf(f))
            ? slugOf(f)
            : throw FormatException('two photos share the slug ${slugOf(f)}'),
        title: _nonEmpty(captions[f]?.title) ?? titleOf(f),
        text: _nonEmpty(captions[f]?.text) ?? defaultItemText,
      ),
  ];
}

String? _nonEmpty(String? s) => s == null || s.isEmpty ? null : s;

/// Same list, shuffled reproducibly when [seed] is set.
List<T> seededOrder<T>(List<T> list, int? seed) =>
    seed == null ? [...list] : ([...list]..shuffle(math.Random(seed)));

String itemImage(String siteId, Photo p) =>
    'assets/items/$siteId-${p.slug}.webp';

/// items.json: spot N gets photo N.
String itemsJson(
  String siteId,
  List<({String id, GeoPoint point})> spots,
  List<Photo> photos, {
  double radiusMeters = 20,
}) {
  if (spots.length != photos.length) {
    throw ArgumentError('${spots.length} spots for ${photos.length} photos');
  }
  return '${_pretty.convert({
    'items': [
      for (var i = 0; i < spots.length; i++) {'id': spots[i].id, 'title': photos[i].title, 'text': photos[i].text, 'image': itemImage(siteId, photos[i]), 'lat': _round(spots[i].point.lat), 'lng': _round(spots[i].point.lng), 'radiusMeters': radiusMeters},
    ],
  })}\n';
}
