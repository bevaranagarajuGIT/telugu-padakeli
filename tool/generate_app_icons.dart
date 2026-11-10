import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

Future<void> main() async {
  final masterFile = File('assets/artwork/branding/app-icon.png');
  final decoded = img.decodePng(await masterFile.readAsBytes());
  if (decoded == null ||
      decoded.width != 1024 ||
      decoded.height != 1024 ||
      !decoded.every((pixel) => pixel.a == 255)) {
    throw FormatException('The app-icon master must be opaque 1024x1024 PNG.');
  }
  // RGB avoids rounding opaque alpha down to 254 during average resizing.
  final master = decoded.convert(numChannels: 3);
  if (decoded.numChannels != 3) {
    await masterFile.writeAsBytes(img.encodePng(master));
  }

  final project = File('ios/Runner.xcodeproj/project.pbxproj');
  final nonIconSetting = RegExp(
    r'^[ \t]*ASSETCATALOG_(?!COMPILER_APPICON_NAME\b)\w+[ \t]*=[^;\r\n]*;',
    multiLine: true,
  );
  final originalSettings = nonIconSetting
      .allMatches(await project.readAsString())
      .map((match) => match.group(0)!)
      .toList();

  late final int result;
  try {
    final generator = await Process.start(Platform.resolvedExecutable, [
      'run',
      'flutter_launcher_icons',
    ], mode: ProcessStartMode.inheritStdio);
    result = await generator.exitCode;
  } finally {
    // The generator also rewrites unrelated Xcode asset-catalog booleans.
    final generated = await project.readAsString();
    if (nonIconSetting.allMatches(generated).length !=
        originalSettings.length) {
      throw StateError('Xcode asset settings changed structure; inspect them.');
    }
    var index = 0;
    final corrected = generated.replaceAllMapped(
      nonIconSetting,
      (_) => originalSettings[index++],
    );
    if (corrected != generated) {
      await project.writeAsString(corrected);
      stdout.writeln('Preserved non-icon Xcode asset-catalog settings.');
    }
  }
  if (result != 0) {
    throw ProcessException(
      Platform.resolvedExecutable,
      ['run', 'flutter_launcher_icons'],
      'Launcher icon generation failed.',
      result,
    );
  }

  final manifest =
      jsonDecode(await File('web/manifest.json').readAsString())
          as Map<String, dynamic>;
  for (final entry
      in (manifest['icons'] as List).cast<Map<String, dynamic>>()) {
    if (entry['purpose'] != 'maskable') continue;
    final size = int.parse((entry['sizes'] as String).split('x').first);
    final contentSize = (size * .8).floor();
    final content = img.copyResize(
      master,
      width: contentSize,
      height: contentSize,
      interpolation: img.Interpolation.average,
    );
    final icon = img.Image(width: size, height: size, numChannels: 3);
    img.fill(icon, color: img.ColorRgb8(32, 165, 245));
    final inset = (size - contentSize) ~/ 2;
    img.compositeImage(
      icon,
      content,
      dstX: inset,
      dstY: inset,
      blend: img.BlendMode.direct,
    );
    await File('web/${entry['src']}').writeAsBytes(img.encodePng(icon));
  }
  stdout.writeln('Generated PWA maskable icons with an 80% content area.');
}
