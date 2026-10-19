// Applies a content pack: generates lib/config/pack.g.dart and installs brand, sites and items.
// Run from the repo root; see tool/mapgen/README.md.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'src/manifest.dart';
import 'src/pack.dart';

const _generated = 'lib/config/pack.g.dart';
const _notifySizes = {
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};

final _parser = ArgParser()
  ..addFlag(
    'check',
    negatable: false,
    help: 'Exit 1 if $_generated is stale; change nothing.',
  )
  ..addFlag(
    'no-icons',
    negatable: false,
    help: 'Skip flutter_launcher_icons and flutter_native_splash.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

Future<void> main(List<String> args) async {
  final ArgResults opts;
  try {
    opts = _parser.parse(args);
  } on FormatException catch (e) {
    _usage(e.message);
    exit(64);
  }
  if (opts.flag('help')) {
    _usage();
    return;
  }
  if (opts.rest.length > 1) {
    _usage('expected at most one pack directory');
    exit(64);
  }
  final packDir = opts.rest.isEmpty ? 'pack' : opts.rest.single;
  final packFile = File('$packDir/pack.json');
  if (!packFile.existsSync()) {
    stderr.writeln('No ${packFile.path}');
    exit(66);
  }
  final pack = jsonDecode(packFile.readAsStringSync()) as Map<String, dynamic>;
  final String source;
  try {
    source = packDart(pack);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(65);
  }

  if (opts.flag('check')) {
    final current = File(_generated);
    if (!current.existsSync() || current.readAsStringSync() != source) {
      stderr.writeln(
        '$_generated is stale: run dart run tool/apply_pack.dart $packDir',
      );
      exit(1);
    }
    stdout.writeln('$_generated is up to date');
    return;
  }

  if (_differentDir(packDir, 'pack')) _install(packDir);
  File(_generated).writeAsStringSync(source);
  stdout.writeln('wrote $_generated');
  _brand(pack);
  if (opts.flag('no-icons')) return;
  if (!File('pack/brand/icon.png').existsSync() ||
      !File('pack/brand/splash.png').existsSync()) {
    stderr.writeln('warning: pack/brand icon or splash missing, icons skipped');
    return;
  }
  await _run('dart', ['run', 'flutter_launcher_icons']);
  await _run('dart', ['run', 'flutter_native_splash:create']);
  for (final dir in ['values', 'values-night']) {
    final f = File('android/app/src/main/res/$dir/styles.xml');
    if (f.existsSync()) {
      f.writeAsStringSync(guardSplashStyles(f.readAsStringSync()));
    }
  }
}

void _usage([String? error]) {
  if (error != null) stderr.writeln(error);
  stdout
    ..writeln(
      'Usage: dart run tool/apply_pack.dart [<packDir>] [--check] [--no-icons]',
    )
    ..writeln('  <packDir> defaults to pack (the active pack in this repo).')
    ..writeln(_parser.usage);
}

bool _differentDir(String a, String b) =>
    Directory(a).absolute.uri.normalizePath() !=
    Directory(b).absolute.uri.normalizePath();

/// Copies an external pack over the active one.
void _install(String packDir) {
  File('$packDir/pack.json').copySync('pack/pack.json');
  _replaceDir('$packDir/brand', 'pack/brand');
  _replaceDir('$packDir/sites', 'assets/sites');
  _replaceDir('$packDir/items', 'assets/items');
  stdout.writeln('installed $packDir');
}

/// Replaces [dest]'s contents with [src]'s, keeping `.gitkeep`.
void _replaceDir(String src, String dest) {
  final from = Directory(src);
  if (!from.existsSync()) {
    stderr.writeln('warning: no $src, $dest left as is');
    return;
  }
  final to = Directory(dest)..createSync(recursive: true);
  for (final e in to.listSync()) {
    if (e.uri.pathSegments.last != '.gitkeep') e.deleteSync(recursive: true);
  }
  for (final e in from.listSync(recursive: true)) {
    final rel = e.path.substring(from.path.length + 1);
    if (e is Directory) {
      Directory('$dest/$rel').createSync(recursive: true);
    } else if (e is File) {
      File('$dest/$rel').parent.createSync(recursive: true);
      e.copySync('$dest/$rel');
    }
  }
}

/// Logo, notification icon, pubspec asset entries and icon/splash colours.
void _brand(Map<String, dynamic> pack) {
  final logo = File('pack/brand/logo.png');
  if (logo.existsSync()) {
    Directory('assets/brand').createSync(recursive: true);
    logo.copySync('assets/brand/logo.png');
  } else {
    stderr.writeln('warning: no pack/brand/logo.png');
  }
  const notify = 'pack/brand/ic_stat_notify.png';
  if (File(notify).existsSync()) {
    final r = Process.runSync('python3', [
      '-E',
      '-P',
      'tool/src/scale_png.py',
      notify,
      for (final e in _notifySizes.entries)
        '${e.value}:android/app/src/main/res/drawable-${e.key}/ic_stat_notify.png',
    ]);
    if (r.exitCode != 0) {
      stderr.writeln('scale_png.py failed: ${r.stderr}');
      exit(1);
    }
  } else {
    stderr.writeln('warning: no $notify');
  }
  final ids = _existingSites();
  final pubspec = File('pubspec.yaml');
  final ink = '#${hexColor(pack['palette'] as Map<String, dynamic>, 'ink')}';
  pubspec.writeAsStringSync(
    withBrandColor(withSiteAssets(pubspec.readAsStringSync(), ids), ink),
  );
  stdout.writeln('pubspec: sites ${ids.join(', ')}; icon colour $ink');
}

/// Index entries whose directory exists; Flutter fails on missing asset dirs.
List<String> _existingSites() {
  final index = File('assets/sites/index.json');
  if (!index.existsSync()) return const [];
  final ids = <String>[];
  for (final id in siteIds(index.readAsStringSync())) {
    if (Directory('assets/sites/$id').existsSync()) {
      ids.add(id);
    } else {
      stderr.writeln('warning: assets/sites/$id/ missing, not declared');
    }
  }
  return ids;
}

Future<void> _run(String cmd, List<String> args) async {
  stdout.writeln('\$ $cmd ${args.join(' ')}');
  final p = await Process.start(cmd, args, mode: ProcessStartMode.inheritStdio);
  final code = await p.exitCode;
  if (code != 0) exit(code);
}
