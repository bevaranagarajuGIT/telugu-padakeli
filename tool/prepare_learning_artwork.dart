import 'dart:io';
import 'package:image/image.dart' as img;

void retainMainObject(img.Image cell) {
  final visited = List.filled(cell.width * cell.height, false);
  var main = <int>[];
  for (var start = 0; start < visited.length; start++) {
    if (visited[start]) continue;
    visited[start] = true;
    if (cell.getPixel(start % cell.width, start ~/ cell.width).a == 0) continue;
    final component = <int>[start];
    for (var cursor = 0; cursor < component.length; cursor++) {
      final index = component[cursor];
      final x = index % cell.width;
      final y = index ~/ cell.width;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= cell.width || ny < 0 || ny >= cell.height) {
            continue;
          }
          final next = ny * cell.width + nx;
          if (visited[next]) continue;
          visited[next] = true;
          if (cell.getPixel(nx, ny).a > 0) component.add(next);
        }
      }
    }
    if (component.length > main.length) main = component;
  }
  final retained = main.toSet();
  for (var index = 0; index < visited.length; index++) {
    if (!retained.contains(index)) {
      cell.setPixelRgba(index % cell.width, index ~/ cell.width, 0, 0, 0, 0);
    }
  }
}

void main(List<String> arguments) {
  if (arguments.length != 1) {
    throw ArgumentError('Pass the approved original 3-by-3 vocabulary PNG.');
  }
  final source = img.decodePng(File(arguments.single).readAsBytesSync());
  if (source == null || source.width != source.height) {
    throw const FormatException('Expected a square PNG vocabulary sheet.');
  }
  const names = [
    'mango',
    'parrot',
    'book',
    'banana',
    'lotus',
    'cat',
    'fish',
    'pencil',
    'elephant',
  ];
  for (var index = 0; index < names.length; index++) {
    final left = source.width * (index % 3) ~/ 3;
    final top = source.height * (index ~/ 3) ~/ 3;
    final right = source.width * (index % 3 + 1) ~/ 3;
    final bottom = source.height * (index ~/ 3 + 1) ~/ 3;
    final cell = img.copyCrop(
      source,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    retainMainObject(cell);
    final canvas = img.Image(width: 512, height: 512, numChannels: 4);
    final picture = img.copyResize(
      cell,
      width: 440,
      height: 440,
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(
      canvas,
      picture,
      dstX: 36,
      dstY: 36,
      blend: img.BlendMode.direct,
    );
    File(
      'assets${Platform.pathSeparator}artwork${Platform.pathSeparator}'
      'kids${Platform.pathSeparator}${names[index]}.png',
    ).writeAsBytesSync(img.encodePng(canvas));
  }
}
