import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'diagnostics.dart';

class ProblemReport {
  const ProblemReport(this.text);
  final String text;

  factory ProblemReport.create({
    required String description,
    required String version,
    required String platform,
    required List<DiagnosticEvent>? diagnostics,
  }) => ProblemReport(
    [
      'Telugu Padakeli — Problem report',
      'App: $version',
      'Platform: $platform',
      '',
      'What happened:',
      description.trim(),
      '',
      if (diagnostics == null)
        'Diagnostics: not included.'
      else ...[
        'Optional diagnostics (UTC; screen, level and error categories only):',
        if (diagnostics.isEmpty) 'No recent diagnostic events.',
        ...diagnostics.map((event) => jsonEncode(event.toJson())),
      ],
    ].join('\n'),
  );

  Uint8List get bytes => Uint8List.fromList(utf8.encode(text));
}

abstract interface class ProblemReporter {
  Future<String> appVersion();
  Future<ShareResultStatus> share(ProblemReport report, Rect origin);
}

class NativeProblemReporter implements ProblemReporter {
  const NativeProblemReporter();

  @override
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  @override
  Future<ShareResultStatus> share(ProblemReport report, Rect origin) async =>
      (await SharePlus.instance.share(
        ShareParams(
          title: 'Telugu Padakeli problem report',
          subject: 'Telugu Padakeli problem report',
          files: [XFile.fromData(report.bytes, mimeType: 'text/plain')],
          fileNameOverrides: ['telugu-padakeli-report.txt'],
          sharePositionOrigin: origin,
        ),
      )).status;
}

String get reportPlatform => kIsWeb ? 'web' : defaultTargetPlatform.name;
