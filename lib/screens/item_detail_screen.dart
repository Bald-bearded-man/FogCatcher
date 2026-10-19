import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../widgets/pixel_kit.dart';
import '../widgets/reveal_overlay.dart' show itemImage;

/// Device-local date + time, e.g. Jun 1, 2030 at 09:00.
String formatFoundDate(DateTime t, AppLocalizations l10n) {
  final l = t.toLocal();
  return l10n.foundDateTime(
    DateFormat.yMMMd('en').format(l),
    DateFormat.Hm('en').format(l),
  );
}

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.foundAt,
  });
  final Item item;
  final DateTime foundAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = formatFoundDate(foundAt, l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.title,
          style: const TextStyle(fontFamily: pixelTitleFont, fontSize: 14),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PixelPanel(
              child: SizedBox(
                height: 240,
                child: itemImage(item.image, label: item.title),
              ),
            ),
            const SizedBox(height: 16),
            Text(item.text, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text(
              l10n.foundAt(date),
              style: const TextStyle(fontSize: 20, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
