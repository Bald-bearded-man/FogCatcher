# Content tools: sites, maps, items, packs and tiles

Offline tools that build the bundled content under `assets/` and `lib/config/pack.g.dart`. Nothing here runs in the app.
Run every command from the repo root. Python helpers need Pillow (with WebP support).

## New site (`tool/new_site.dart`)

```sh
dart run tool/new_site.dart --id <id> --name "<display name>" --center <lat>,<lng> --radius <m> --photos <dir> \
  [--captions captions.csv] [--count N] [--spacing M] [--boundary way/<id>|relation/<id>] \
  [--refresh] [--seed <int>] [--preview out.png] [--no-test]
dart run tool/new_site.dart --help
```

The demo site's spots were built with this command; its photos and captions were then replaced by hand (sources in `assets/items/CREDITS.md`):

```sh
dart run tool/new_site.dart --id champ_de_mars --name "Champ de Mars" --center 48.8556,2.2984 --radius 560 \
  --boundary way/4208595 --count 12 --spacing 60 --photos <dir> --captions <dir>/captions.csv
```

Steps, in order:

1. Writes `assets/sites/<id>/site.json`: centre, radius, bounds (the circle's box plus 10 m), optional `boundary`.
2. Fetches OSM data (cached, see Tilemaps) and writes `assets/sites/<id>/tilemap.json`.
   A changed `site.json` refetches automatically; `--refresh` forces it.
3. Builds the catalogue from the photos in `--photos` (jpg, jpeg, png, webp, gif, bmp):
   - With `--captions`, a CSV with header `file,title,text` gives the titles and texts. Captioned photos come first, in CSV order.
   - Other photos follow in filename order. Their title comes from the filename: a leading number is dropped,
     dashes and underscores become spaces, and each word is capitalised (`01_kite_lawn.png` → "Kite Lawn").
     Their text is a neutral default.
   - `--seed` shuffles the catalogue reproducibly. Without it, spot N gets photo N.
   - `--count` keeps the first N photos (default: all of them).
4. Picks the spots (see Item spots). If fewer than `--count` spots fit, it fails: lower `--spacing` or `--count`.
5. Resizes the photos to at most 960 px and saves them as `assets/items/<id>-<slug>.webp`, replacing that site's old
   photos. It uses `tool/src/webp.py`, because package:image cannot encode WebP. Few-colour art is stored lossless.
6. Writes `assets/sites/<id>/items.json` and `tool/mapgen/seed/<id>.json` (spot landmarks, used by the solution maps).
7. Adds the id to `assets/sites/index.json` and rewrites the `flutter.assets` list in `pubspec.yaml`
   (Flutter asset directories are not recursive, so each `assets/sites/<id>/` needs its own entry).
8. Runs `flutter test test/content` unless `--no-test` is passed.

Rerunning with the same arguments is deterministic. To fix one caption, edit `assets/sites/<id>/items.json` by hand
and run `flutter test test/content`, or edit the CSV and rerun.

## Content pack (`tool/apply_pack.dart`)

```sh
dart run tool/apply_pack.dart [<packDir>] [--check] [--no-icons]
```

- `<packDir>` defaults to `pack`. With another dir, it copies its `pack.json` and `brand/` into `pack/`,
  and its `sites/` and `items/` over `assets/sites/` and `assets/items/`.
- It always does the following:
  - generates `lib/config/pack.g.dart`;
  - copies `brand/logo.png` to `assets/brand/`;
  - scales `brand/ic_stat_notify.png` into `android/app/src/main/res/drawable-*` with `tool/src/scale_png.py`;
  - rewrites the pubspec site asset entries from `index.json`;
  - sets the launcher icon background and splash colour to `palette.ink`;
  - runs `flutter_launcher_icons` and `flutter_native_splash:create`. `--no-icons` skips this step.
- `--check` exits 1 if `lib/config/pack.g.dart` is stale and changes nothing. The gate runs it.

Schema and layout: `docs/content-packs.md`.

## Tilemaps (`tool/mapgen/main.dart`)

```sh
dart run tool/mapgen/main.dart --site <id> [--refresh] [--preview build/mapgen/<id>.png]
```

- Reads `assets/sites/<id>/site.json`, paints the OSM features onto a 4 m grid and writes `assets/sites/<id>/tilemap.json`.
- OSM data is cached in `cache/<id>.osm.json` (git-ignored). `--refresh` refetches it from Overpass
  (overpass-api.de, then overpass.private.coffee). If every mirror fails, it falls back to one OSM API `map` call,
  which only works for small sites: bbox up to 0.25 deg² (refused with an error above that) and about 50 000 nodes.
- Void cells (black, unplayable):
  - golf course areas and golf features: a `golf=hole` line becomes a 60 m corridor; tees, greens, bunkers, fairways,
    rough and driving ranges grow by 10 m;
  - archery, `access=private|no` (pools excepted), and farmland, railway, construction or military land;
  - everything outside the site boundary. That is `site.json` `"boundary": "way/<id>"` or `"relation/<id>"`
    (a closed OSM way or multipolygon; keep `--radius` large enough to enclose it) when set, the radius circle otherwise;
  - polygons in `overrides/<id>.json`.
- To void an extra area after a site visit, add a polygon to `overrides/<id>.json` and rerun:
  `{"void": [[{"lat": 48.85, "lng": 2.29}, ...]]}`.
- `--preview` writes a PNG with one pixel per cell and the items as orange squares.

## Item spots (`tool/mapgen/seed/spots.dart`)

`pickSpots()` is the library that `new_site` calls. `pick.dart` re-picks spots for an existing site without touching
`items.json`, which is useful for tuning:

```sh
dart run tool/mapgen/seed/pick.dart --site <id> [--count 20] [--spacing 60] [--zone S,W,N,E:K] [--verbose]
```

- It ranks OSM landmarks (pools, restaurants and cafés, historic sites, pitches and parks, other POIs and named
  buildings), then optional `--zone` cells (off-path, clear of void, 30 m from roads), then path cells.
- It snaps each spot to a walkable cell within 8 m of a path or road, with void at least 28 m away,
  inside the circle, and at least `--spacing` metres from the other spots.
- It writes `seed/<id>.json`. POI nodes are cached in `cache/<id>.pois.osm.json` (git-ignored).

## Solution maps

```sh
python3 tool/solution/make_solution_maps.py build/solution [tile_cache_dir]
```

Writes one answer-key PNG per site in `assets/sites/index.json`, plus `solutions.pdf`. Each map is the real OSM map
with numbered markers and a legend. The heading is the site name and the zoom is fitted to the radius.
Never ship the output.

## Tiles

```sh
python3 tool/mapgen/make_tiles.py <kenney_tiny-town dir> <kenney_tiny-dungeon dir>
```

Builds `assets/tiles/tileset.png` and `sprites.png` in the order fixed by `lib/models/tileset_layout.dart`.
Sources and licences: `assets/tiles/LICENSE-kenney.txt`.
