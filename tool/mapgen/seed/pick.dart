// Re-picks item spots for an existing site without touching items.json (new_site.dart does the full run).
// Usage: dart run tool/mapgen/seed/pick.dart --site <id> [--count 20] [--spacing 60] [--zone S,W,N,E:K] [--verbose]
//   --zone adds up to K off-path spots in that box, clear of void and 30 m from roads
//   writes tool/mapgen/seed/<id>.json; run tool/mapgen/main.dart for the site first.
import 'dart:io';

import 'package:fogcatcher/models/site.dart';
import 'package:fogcatcher/models/tile_map.dart';

import '../mapgen.dart';
import '../osm.dart';
import 'spots.dart';

Future<void> main(List<String> args) async {
  String? arg(String n) {
    final i = args.indexOf(n);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final id = arg('--site');
  if (id == null) {
    stderr.writeln('Usage: see header of tool/mapgen/seed/pick.dart');
    exit(64);
  }
  final site = Site.fromJson(readJson('assets/sites/$id/site.json'));
  final picked = pickSpots(
    site,
    TileMap.fromJson(readJson('assets/sites/$id/tilemap.json')),
    parseFeatures(await loadOsm(site)),
    await loadPois(site),
    count: int.parse(arg('--count') ?? '20'),
    spacing: double.parse(arg('--spacing') ?? '60'),
    zone: arg('--zone'),
    verbose: args.contains('--verbose'),
  );
  final seedFile = File('tool/mapgen/seed/$id.json')
    ..writeAsStringSync(seedJson(id, picked));
  stdout.writeln('${picked.length} spots → ${seedFile.path}');
  for (var i = 0; i < picked.length; i++) {
    stdout.writeln('  ${spotId(id, i)}  ${picked[i].landmark}');
  }
}
