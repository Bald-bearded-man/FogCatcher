import 'dart:io';
import 'dart:typed_data';

/// Minimal RGB PNG encoder for previews; avoids an image package dependency.
Uint8List encodeRgbPng(int width, int height, Uint8List rgb) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter: none
    raw.add(Uint8List.sublistView(rgb, y * width * 3, (y + 1) * width * 3));
  }
  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2); // colour type RGB
  return (BytesBuilder()
        ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_chunk('IHDR', ihdr.buffer.asUint8List()))
        ..add(_chunk('IDAT', ZLibCodec().encode(raw.takeBytes())))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

List<int> _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final len = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc32(body));
  return [...len.buffer.asUint8List(), ...body, ...crc.buffer.asUint8List()];
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
