/// Player avatars, in the frame order of assets/tiles/avatars.png.
enum Avatar {
  explorerGirl,
  explorerBoy,
  mage,
  knight,
  alien,
  robot,
  ninja,
  pirate,
  astronaut,
  slime;

  static const fallback = Avatar.explorerBoy;
  static const framesPerAvatar = 2;
  static int get frameCount => values.length * framesPerAvatar;

  /// Idle frame for `bob == 0`, bob frame for `bob == 1`.
  int frame(int bob) => index * framesPerAvatar + bob;

  /// Unknown or missing names fall back to [fallback].
  static Avatar fromName(String? name) =>
      values.where((a) => a.name == name).firstOrNull ?? fallback;
}
