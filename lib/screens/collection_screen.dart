import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../widgets/pixel_kit.dart';
import '../widgets/reveal_overlay.dart' show itemImage;
import 'item_detail_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({
    super.key,
    required this.items,
    required this.found,
    required this.onShare,
  });
  final List<Item> items;
  final Map<String, DateTime> found;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = items.where((i) => found.containsKey(i.id)).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.collectionTitle,
          style: const TextStyle(fontFamily: pixelTitleFont, fontSize: 14),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: PixelPanel(
                fill: AppColors.shade,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l10n.score(count, items.length),
                  style: const TextStyle(
                    fontFamily: pixelTitleFont,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final at = found[item.id];
                return at == null
                    ? _LockedTile(label: l10n.lockedItem)
                    : _FoundTile(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ItemDetailScreen(item: item, foundAt: at),
                          ),
                        ),
                      );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PixelButton(label: l10n.shareScore, onPressed: onShare),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundTile extends StatelessWidget {
  const _FoundTile({required this.item, required this.onTap});
  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: PixelPanel(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Expanded(child: itemImage(item.image, label: item.title)),
          const SizedBox(height: 4),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 0.9),
          ),
        ],
      ),
    ),
  );
}

class _LockedTile extends StatelessWidget {
  const _LockedTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => PixelPanel(
    borderColor: AppColors.alert,
    child: Center(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: pixelTitleFont,
          fontSize: 16,
          color: AppColors.alert,
        ),
      ),
    ),
  );
}
