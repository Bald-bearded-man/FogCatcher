import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // No JVM tests here: guard the native fix at the source level.
  test('Back at the map root backgrounds the task instead of finishing', () {
    final src = File(
      'android/app/src/main/kotlin/com/baldman/fogcatcher/MainActivity.kt',
    ).readAsStringSync();
    expect(
      src,
      contains(
        'override fun popSystemNavigator(): Boolean = moveTaskToBack(true)',
      ),
    );
  });

  test('side-by-side builds can change the package via APP_ID_SUFFIX', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.baldman.fogcatcher"'));
    expect(
      gradle,
      contains('applicationIdSuffix = System.getenv("APP_ID_SUFFIX") ?: ""'),
    );
  });

  test('launcher label comes from the pack appName', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('rootProject.file("../pack/pack.json")'));
    expect(gradle, contains('packJson["appName"]'));
    expect(gradle, contains('manifestPlaceholders["appLabel"] = appLabel'));
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains(r'android:label="${appLabel}"'));
  });

  test('pack.json has the appName the build reads', () {
    final pack = jsonDecode(File('pack/pack.json').readAsStringSync()) as Map;
    expect(
      pack['appName'],
      isA<String>().having((s) => s, 'appName', isNotEmpty),
    );
  });
}
