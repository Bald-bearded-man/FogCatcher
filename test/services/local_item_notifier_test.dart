import 'dart:typed_data';

import 'package:fogcatcher/models/geo_point.dart';
import 'package:fogcatcher/models/item.dart';
import 'package:fogcatcher/services/local_item_notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  Object? initError;
  NotificationAppLaunchDetails? launch;
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (initError != null) throw initError!;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launch;

  final shown =
      <
        ({
          int id,
          String? title,
          String? body,
          NotificationDetails? details,
          String? payload,
        })
      >[];
  // 22.x uses named parameters.
  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async => shown.add((
    id: id,
    title: title,
    body: body,
    details: notificationDetails,
    payload: payload,
  ));
}

const _item = Item(
  id: 'o01',
  title: 'Le menhir',
  text: 'texte',
  image: 'assets/x.png',
  position: GeoPoint(1, 1),
);

void main() {
  test('showItemFound posts on item_found with BigPictureStyle', () async {
    final plugin = FakePlugin();
    final n = LocalItemNotifier(
      plugin: plugin,
      loadAsset: (_) async => Uint8List.fromList([1, 2, 3]),
    );
    await n.showItemFound(_item);
    final s = plugin.shown.single;
    final a = s.details!.android!;
    expect(a.channelId, 'item_found');
    expect(a.styleInformation, isA<BigPictureStyleInformation>());
    expect(s.payload, 'item:o01');
    expect(s.body, 'Le menhir');
    // Copy comes from app_en.arb, not literals.
    expect(s.title, 'Item found!');
    expect(a.channelName, 'Items found');
    expect(
      (a.styleInformation! as BigPictureStyleInformation).contentTitle,
      'Item found!',
    );
  });

  test('showItemFound without image posts plain notification', () async {
    final plugin = FakePlugin();
    final n = LocalItemNotifier(plugin: plugin, loadAsset: (_) async => null);
    await n.showItemFound(_item);
    expect(plugin.shown, hasLength(1));
    expect(plugin.shown.single.details!.android!.styleInformation, isNull);
  });

  test('notification id is stable per item', () async {
    final plugin = FakePlugin();
    final n = LocalItemNotifier(plugin: plugin, loadAsset: (_) async => null);
    await n.showItemFound(_item);
    await n.showItemFound(_item);
    expect(plugin.shown[0].id, plugin.shown[1].id);
    expect(plugin.shown[0].id, 'o01'.hashCode & 0x7fffffff);
  });

  test('itemIdFromPayload parses only item: payloads', () {
    expect(LocalItemNotifier.itemIdFromPayload('item:o01'), 'o01');
    expect(LocalItemNotifier.itemIdFromPayload('other:o01'), isNull);
    expect(LocalItemNotifier.itemIdFromPayload('item:'), isNull);
    expect(LocalItemNotifier.itemIdFromPayload(null), isNull);
  });

  test('default asset loader returns null for a missing asset', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await LocalItemNotifier.defaultLoadAsset('assets/nope.png'), isNull);
  });

  test(
    'launch tap delivered before anyone listens is still readable',
    () async {
      final plugin = FakePlugin()
        ..launch = const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'item:o07',
          ),
        );
      final n = LocalItemNotifier(plugin: plugin);
      await n.init();
      expect(n.takeLaunchItemId(), 'o07');
      expect(n.takeLaunchItemId(), isNull);
    },
  );

  test('init survives plugin failures', () async {
    final plugin = FakePlugin()..initError = StateError('boom');
    final n = LocalItemNotifier(plugin: plugin);
    await n.init(); // must not throw
    expect(n.takeLaunchItemId(), isNull);
  });
}
