// Creates or rebuilds a playable site end to end: site.json, tilemap, item photos, spots, items.json.
import 'dart:io';

import 'package:args/args.dart';
import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/site.dart';

import 'mapgen/mapgen.dart';
import 'mapgen/osm.dart';
import 'mapgen/seed/spots.dart';
import 'src/manifest.dart';
import 'src/site_content.dart';

const maxPhotoPx = 960;

ArgParser _parser() => ArgParser()
  ..addOption('id', help: 'Site id, lowercase snake_case (e.g. demo_park).')
  ..addOption('name', help: 'Display name shown in the app.')
  ..addOption('center', help: 'Circle centre as lat,lng.')
  ..addOption('radius', help: 'Circle radius in metres.')
  ..addOption('photos', help: 'Directory of item photos (jpg, png, webp...).')
  ..addOption(
    'captions',
    help:
        'CSV with header file,title,text. Without it titles come from filenames.',
  )
  ..addOption('count', help: 'Number of items (default: every photo).')
  ..addOption(
    'spacing',
    defaultsTo: '60',
    help: 'Minimum metres between items.',
  )
  ..addOption(
    'boundary',
    help:
        'OSM way/<id> or relation/<id> used as the playable area instead of the circle.',
  )
  ..addOption(
    'seed',
    help: 'Shuffles which photo goes to which spot, reproducibly.',
  )
  ..addOption(
    'preview',
    help: 'Also writes a one-pixel-per-cell PNG of the map.',
  )
  ..addFlag('refresh', negatable: false, help: 'Refetch OSM data.')
  ..addFlag(
    'no-test',
    negatable: false,
    help: 'Skip flutter test test/content.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

Never _usage(ArgParser p, [String? error]) {
  if (error != null) stderr.writeln('error: $error\n');
  (error == null ? stdout : stderr).writeln(
    'Usage: dart run tool/new_site.dart --id <id> --name <name> --center lat,lng '
    '--radius <m> --photos <dir> [options]\n'
    'Run from the repo root. Writes assets/sites/<id>/, assets/items/<id>-*.webp, '
    'assets/sites/index.json and pubspec.yaml asset entries.\n\n${p.usage}',
  );
  exit(error == null ? 0 : 64);
}

Future<void> main(List<String> argv) async {
  final parser = _parser();
  final ArgResults a;
  try {
    a = parser.parse(argv);
  } on FormatException catch (e) {
    _usage(parser, e.message);
  }
  if (a.flag('help')) _usage(parser);
  String req(String name) =>
      a.option(name) ?? _usage(parser, '--$name is required');
  int? intOpt(String name) => a.option(name) == null
      ? null
      : int.tryParse(a.option(name)!) ??
            _usage(parser, '--$name must be an integer');

  final id = req('id');
  if (!validSiteId(id)) _usage(parser, '--id must match [a-z][a-z0-9_]*');
  final name = req('name');
  final c = req('center').split(',').map((s) => double.tryParse(s.trim()));
  if (c.length != 2 || c.contains(null)) {
    _usage(parser, '--center must be lat,lng');
  }
  final center = GeoPoint(c.first!, c.last!);
  final radius = double.tryParse(req('radius')) ?? 0;
  if (radius <= 0) _usage(parser, '--radius must be a positive number');
  final spacing = double.tryParse(a.option('spacing')!) ?? 0;
  if (spacing <= 0) _usage(parser, '--spacing must be a positive number');
  final boundary = a.option('boundary');
  if (boundary != null) {
    try {
      boundaryOf({'boundary': boundary});
    } on FormatException catch (e) {
      _usage(parser, e.message);
    }
  }
  final photosDir = Directory(req('photos'));
  if (!photosDir.existsSync()) _usage(parser, '${photosDir.path} not found');

  final files = [
    for (final f in photosDir.listSync().whereType<File>())
      if (photoExtensions.any((e) => f.path.toLowerCase().endsWith(e)))
        f.uri.pathSegments.last,
  ];
  final captions = a.option('captions');
  final catalogue = seededOrder(
    buildCatalogue(
      files,
      csv: captions == null ? null : File(captions).readAsStringSync(),
    ),
    intOpt('seed'),
  );
  final count = intOpt('count') ?? catalogue.length;
  if (count < 1 || count > catalogue.length) {
    _usage(parser, '--count must be 1..${catalogue.length} (photos found)');
  }
  final photos = catalogue.take(count).toList();

  final siteDir = Directory('assets/sites/$id')..createSync(recursive: true);
  final siteFile = File('${siteDir.path}/site.json');
  final json = siteJson(
    id: id,
    name: name,
    center: center,
    radiusMeters: radius,
    boundary: boundary,
  );
  // A moved or resized circle needs fresh OSM data for the new bounds.
  final moved = !siteFile.existsSync() || siteFile.readAsStringSync() != json;
  siteFile.writeAsStringSync(json);
  final refresh = a.flag('refresh') || moved;

  final map = await buildTilemap(id, refresh: refresh);
  printStats(map);
  final site = Site.fromJson(readJson(siteFile.path));
  final spots = pickSpots(
    site,
    map,
    parseFeatures(await loadOsm(site)),
    await loadPois(site, refresh: refresh),
    count: count,
    spacing: spacing,
  );
  if (spots.length < count) {
    stderr.writeln(
      'only ${spots.length} spots fit for $count photos: '
      'lower --spacing or --count, or widen --radius',
    );
    exit(1);
  }

  await _encodePhotos(id, photosDir, photos);
  final ids = [for (var i = 0; i < count; i++) spotId(id, i)];
  File('${siteDir.path}/items.json').writeAsStringSync(
    itemsJson(id, [
      for (var i = 0; i < count; i++) (id: ids[i], point: spots[i].point),
    ], photos),
  );
  File('tool/mapgen/seed/$id.json').writeAsStringSync(seedJson(id, spots));
  for (var i = 0; i < count; i++) {
    stdout.writeln('  ${ids[i]}  ${photos[i].title}  ←  ${spots[i].landmark}');
  }

  final index = File('assets/sites/index.json');
  final indexJson = withSite(
    index.existsSync() ? index.readAsStringSync() : encodeIndex(const []),
    id,
  );
  index.writeAsStringSync(indexJson);
  final pubspec = File('pubspec.yaml');
  pubspec.writeAsStringSync(
    withSiteAssets(pubspec.readAsStringSync(), siteIds(indexJson)),
  );
  stdout.writeln('updated ${index.path} and ${pubspec.path}');

  final preview = a.option('preview');
  if (preview != null) {
    File(preview)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(renderPreview(map, itemPoints(id), site));
    stdout.writeln('preview: $preview');
  }
  if (a.flag('no-test')) return;
  final test = await Process.start('flutter', [
    'test',
    'test/content',
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await test.exitCode;
}

/// Replaces this site's photos in assets/items/ via the Pillow helper.
Future<void> _encodePhotos(String id, Directory dir, List<Photo> photos) async {
  for (final old in Directory('assets/items').listSync().whereType<File>()) {
    if (old.uri.pathSegments.last.startsWith('$id-')) old.deleteSync();
  }
  // -E -P: ignore PYTHON* env and keep the photo dir off sys.path (Pillow may live in the user site).
  final r = await Process.run('python3', [
    '-E',
    '-P',
    'tool/src/webp.py',
    '$maxPhotoPx',
    for (final p in photos) ...['${dir.path}/${p.file}', itemImage(id, p)],
  ]);
  stdout.write(r.stdout);
  if (r.exitCode != 0) {
    stderr.write(r.stderr);
    exit(1);
  }
}
