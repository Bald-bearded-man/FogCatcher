import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'interfaces.dart';

// coverage:ignore-file
class SharePlusSharer implements ScoreSharer {
  @override
  Future<void> sharePng(Uint8List png, {required String caption}) async {
    final path = '${(await getTemporaryDirectory()).path}/fogcatcher-score.png';
    await File(path).writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'image/png')],
        text: caption,
      ),
    );
  }
}
