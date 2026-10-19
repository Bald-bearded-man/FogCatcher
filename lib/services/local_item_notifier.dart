import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/theme.dart';
import '../l10n/app_strings.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/item.dart';
import 'interfaces.dart';

class LocalItemNotifier implements ItemFoundNotifier {
  LocalItemNotifier({
    FlutterLocalNotificationsPlugin? plugin,
    Future<Uint8List?> Function(String asset)? loadAsset,
    AppLocalizations? strings,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _loadAsset = loadAsset ?? defaultLoadAsset,
       _l10n = strings ?? appStrings;

  static const channelId = 'item_found';
  static const _prefix = 'item:';

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<Uint8List?> Function(String asset) _loadAsset;
  final AppLocalizations _l10n;
  final _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  static String? itemIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_prefix)) return null;
    final id = payload.substring(_prefix.length);
    return id.isEmpty ? null : id;
  }

  static Future<Uint8List?> defaultLoadAsset(String asset) async {
    try {
      final d = await rootBundle.load(asset);
      return d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes);
    } catch (_) {
      return null;
    }
  }

  void _route(String? payload) {
    final id = itemIdFromPayload(payload);
    if (id != null) _taps.add(id);
  }

  String? _launchItemId;

  /// Item id of a tap that launched the app; read once after [init].
  @override
  String? takeLaunchItemId() {
    final id = _launchItemId;
    _launchItemId = null;
    return id;
  }

  // Each step is isolated so a failure never breaks app start.
  @override
  Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notify'),
        ),
        onDidReceiveNotificationResponse: (r) => _route(r.payload),
      );
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
    try {
      // Created eagerly: the plugin only makes a channel on first show.
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              channelId,
              _l10n.itemsFoundChannel,
              importance: Importance.high,
            ),
          );
    } catch (e) {
      debugPrint('Notification channel failed: $e');
    }
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchItemId = itemIdFromPayload(
          launch!.notificationResponse?.payload,
        );
      }
    } catch (e) {
      debugPrint('Notification launch details failed: $e');
    }
  }

  @override
  Future<void> showItemFound(Item item) async {
    final bytes = await _loadAsset(item.image);
    final style = bytes == null
        ? null
        : BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: ByteArrayAndroidBitmap(bytes),
            contentTitle: _l10n.itemFoundTitle,
            summaryText: item.title,
          );
    await _plugin.show(
      id: item.id.hashCode & 0x7fffffff,
      title: _l10n.itemFoundTitle,
      body: item.title,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _l10n.itemsFoundChannel,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notify',
          color: AppColors.accent,
          styleInformation: style,
        ),
      ),
      payload: '$_prefix${item.id}',
    );
  }
}
