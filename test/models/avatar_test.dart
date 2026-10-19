import 'package:fogcatcher/models/avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('avatar i uses frames 2i and 2i+1 of a 20-frame strip', () {
    expect(Avatar.frameCount, 20);
    expect(
      [Avatar.explorerGirl.frame(0), Avatar.explorerGirl.frame(1)],
      [0, 1],
    );
    expect([Avatar.slime.frame(0), Avatar.slime.frame(1)], [18, 19]);
  });

  test('fromName round-trips and falls back to the adventurer', () {
    for (final a in Avatar.values) {
      expect(Avatar.fromName(a.name), a);
    }
    expect(Avatar.fromName(null), Avatar.explorerBoy);
    expect(Avatar.fromName('dragon'), Avatar.explorerBoy);
  });
}
