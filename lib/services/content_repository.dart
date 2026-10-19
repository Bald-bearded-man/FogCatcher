import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/item.dart';
import '../models/site.dart';
import '../models/tile_map.dart';

class SiteBundle {
  const SiteBundle(this.site, this.items, this.map);
  final Site site;
  final List<Item> items;
  final TileMap map;
}

class ContentRepository {
  ContentRepository(this._bundle);
  final AssetBundle _bundle;

  Future<Map<String, dynamic>> _json(String path) async =>
      jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;

  Future<List<SiteBundle>> loadAll() async {
    final index = await _json('assets/sites/index.json');
    final ids = (index['sites'] as List).cast<String>();
    return [
      for (final id in ids)
        SiteBundle(
          Site.fromJson(await _json('assets/sites/$id/site.json')),
          [
            for (final i
                in (await _json('assets/sites/$id/items.json'))['items']
                    as List)
              Item.fromJson(i as Map<String, dynamic>),
          ],
          TileMap.fromJson(await _json('assets/sites/$id/tilemap.json')),
        ),
    ];
  }
}
