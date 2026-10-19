import 'package:fogcatcher/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('context-free strings come from app_en.arb', () {
    expect(appStrings.exploringNotificationTitle('Demo'), 'Demo — exploring');
    expect(
      appStrings.exploringNotificationBody,
      'Keep the app open in the background to find items.',
    );
    expect(appStrings.explorationChannel, 'Exploration');
    expect(appStrings.itemsFoundChannel, 'Items found');
    expect(
      appStrings.foundDateTime('Jun 1, 2030', '09:00'),
      'Jun 1, 2030 at 09:00',
    );
  });
}
