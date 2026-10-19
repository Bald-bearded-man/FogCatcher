// Rebuilds one site's tilemap.json from OpenStreetMap.
// Usage: dart run tool/mapgen/main.dart --site <id> [--refresh] [--preview out.png]
import 'dart:io';

import 'package:fogcatcher/models/site.dart';

import 'mapgen.dart';

Future<void> main(List<String> args) async {
  String? arg(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final id = arg('--site');
  if (id == null) {
    stderr.writeln(
      'Usage: dart run tool/mapgen/main.dart --site <id> [--refresh] [--preview out.png]',
    );
    exit(64);
  }
  final map = await buildTilemap(id, refresh: args.contains('--refresh'));
  printStats(map);
  final preview = arg('--preview');
  if (preview != null) {
    final site = Site.fromJson(readJson('assets/sites/$id/site.json'));
    File(preview)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(renderPreview(map, itemPoints(id), site));
    stdout.writeln('preview: $preview');
  }
}
