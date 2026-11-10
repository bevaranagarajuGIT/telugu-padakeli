import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const masterPath = 'assets/artwork/branding/app-icon.png';
const androidResources = 'android/app/src/main/res';
const iosCatalog = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

img.Image readIcon(String path) {
  final image = img.decodePng(File(path).readAsBytesSync());
  if (image == null) throw FormatException('Invalid icon PNG: $path');
  return image;
}

bool samePixels(img.Image first, img.Image second) => listEquals(
  first.getBytes(order: img.ChannelOrder.rgba),
  second.getBytes(order: img.ChannelOrder.rgba),
);

void main() {
  test('approved icon master is opaque, square and App Store sized', () {
    final master = readIcon(masterPath);
    expect((master.width, master.height), (1024, 1024));
    expect(master.every((pixel) => pixel.a == 255), isTrue);
  });

  test('Android includes all legacy and adaptive icon densities', () {
    const sizes = {
      'mdpi': (48, 108),
      'hdpi': (72, 162),
      'xhdpi': (96, 216),
      'xxhdpi': (144, 324),
      'xxxhdpi': (192, 432),
    };
    for (final entry in sizes.entries) {
      final legacy = readIcon(
        '$androidResources/mipmap-${entry.key}/ic_launcher.png',
      );
      final foreground = readIcon(
        '$androidResources/drawable-${entry.key}/ic_launcher_foreground.png',
      );
      expect(
        (legacy.width, legacy.height),
        (entry.value.$1, entry.value.$1),
        reason: entry.key,
      );
      expect(
        (foreground.width, foreground.height),
        (entry.value.$2, entry.value.$2),
        reason: entry.key,
      );
    }
    final adaptive = File(
      '$androidResources/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(adaptive, contains('@drawable/ic_launcher_foreground'));
    expect(adaptive, contains('@color/ic_launcher_background'));
    expect(adaptive, contains('android:inset="16%"'));
    final colors = File(
      '$androidResources/values/colors.xml',
    ).readAsStringSync();
    expect(colors.toUpperCase(), contains('#20A5F5'));
  });

  test('all iOS catalog slots exist with correct dimensions and no alpha', () {
    final catalog =
        jsonDecode(File('$iosCatalog/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final entries = (catalog['images'] as List).cast<Map<String, dynamic>>();
    for (final entry in entries) {
      final name = entry['filename'] as String;
      final size = double.parse((entry['size'] as String).split('x').first);
      final scale = double.parse(
        (entry['scale'] as String).replaceAll('x', ''),
      );
      final expected = (size * scale).round();
      final icon = readIcon('$iosCatalog/$name');
      expect((icon.width, icon.height), (expected, expected), reason: name);
      expect(icon.every((pixel) => pixel.a == 255), isTrue, reason: name);
    }
    expect(
      samePixels(
        readIcon(masterPath),
        readIcon('$iosCatalog/Icon-App-1024x1024@1x.png'),
      ),
      isTrue,
      reason: 'The App Store icon must retain the approved artwork.',
    );
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    for (final setting in RegExp(
      r'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = (\w+);',
    ).allMatches(project)) {
      expect(setting.group(1), anyOf('YES', 'NO'));
    }
  });

  test('web icons are wired and maskable images preserve their safe inset', () {
    final master = readIcon(masterPath);
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['name'], 'Telugu Padakeli');
    final entries = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    expect(entries, hasLength(4));
    for (final entry in entries) {
      final size = int.parse((entry['sizes'] as String).split('x').first);
      final icon = readIcon('web/${entry['src']}');
      expect((icon.width, icon.height), (size, size));
      if (entry['purpose'] == 'maskable') {
        final contentSize = (size * .8).floor();
        final inset = (size - contentSize) ~/ 2;
        final content = img.copyCrop(
          icon,
          x: inset,
          y: inset,
          width: contentSize,
          height: contentSize,
        );
        final expected = img.copyResize(
          master,
          width: contentSize,
          height: contentSize,
          interpolation: img.Interpolation.average,
        );
        expect(samePixels(content, expected), isTrue);
        final corner = icon.getPixel(0, 0);
        expect((corner.r, corner.g, corner.b), (32, 165, 245));
      }
    }
    final favicon = readIcon('web/favicon.png');
    expect((favicon.width, favicon.height), (16, 16));
    expect(
      samePixels(
        readIcon('$androidResources/mipmap-xxxhdpi/ic_launcher.png'),
        readIcon('web/icons/Icon-192.png'),
      ),
      isTrue,
    );
  });
}
