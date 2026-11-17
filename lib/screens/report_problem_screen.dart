import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/diagnostics.dart';
import '../services/problem_report.dart';
import '../widgets/app_page.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({
    this.reporter = const NativeProblemReporter(),
    super.key,
  });

  final ProblemReporter reporter;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _description = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _heading = GlobalKey();
  Diagnostics? _diagnostics;
  DiagnosticScreen? _previousScreen;
  int? _previousLevel;
  bool _includeDiagnostics = false;
  bool _busy = false;
  String? _message;
  ProblemReport? _preview;

  @override
  void initState() {
    super.initState();
    _diagnostics = context.read<Diagnostics?>();
    _previousScreen = _diagnostics?.screen;
    _previousLevel = _diagnostics?.level;
    _diagnostics?.location(DiagnosticScreen.report);
  }

  @override
  void dispose() {
    _description.dispose();
    if (_previousScreen != null) {
      _diagnostics?.location(_previousScreen!, level: _previousLevel);
    }
    super.dispose();
  }

  Future<void> _prepare() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final version = await widget.reporter.appVersion();
      if (!mounted) return;
      setState(
        () => _preview = ProblemReport.create(
          description: _description.text,
          version: version,
          platform: reportPlatform,
          diagnostics: _includeDiagnostics ? _diagnostics?.events ?? [] : null,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final heading = _heading.currentContext;
        if (mounted && heading != null) {
          Scrollable.ensureVisible(heading);
        }
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _message =
              'యాప్ వివరాలు తెరవలేకపోయాం. మళ్లీ ప్రయత్నించండి.\n'
              'Could not read the app version. Please retry Preview report.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.reporter.share(_preview!, origin);
      if (!mounted) return;
      setState(
        () => _message = result == ShareResultStatus.dismissed
            ? 'షేర్ చేయడం రద్దయింది. నివేదిక ఇక్కడే ఉంది.\n'
                  'Sharing cancelled. Your report is still here.'
            : 'ఎంచుకున్న యాప్‌లో పంపడం పూర్తి చేయండి.\n'
                  'Finish sending in the app you chose. Delivery is not confirmed.',
      );
    } on Exception {
      if (mounted) {
        setState(
          () => _message =
              'షేర్ చేయలేకపోయాం. మళ్లీ ప్రయత్నించండి.\n'
              'Could not open sharing. Your report is still here; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'సమస్యను తెలియజేయండి',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Report a problem',
          key: _heading,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'ఏం జరిగిందో చెప్పండి. వ్యక్తిగత వివరాలు రాయవద్దు.\n'
          'Describe the problem, not names, contact details or private information. '
          'For children, ask a parent or guardian to help.',
        ),
        const SizedBox(height: 16),
        if (_preview == null) ...[
          Form(
            key: _form,
            child: TextFormField(
              key: const ValueKey('report-description'),
              controller: _description,
              enabled: !_busy,
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ఏం జరిగింది? / What happened?',
                alignLabelWithHint: true,
                helperText: 'Which game or level? What did you expect?',
                helperMaxLines: 3,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'సమస్యను వివరించండి / Please describe the problem.'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            key: const ValueKey('report-include-diagnostics'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('సాంకేతిక వివరాలు / Include diagnostics'),
            subtitle: const Text(
              'Optional: recent screen/level numbers, UTC times and error '
              'categories. No saved answers, raw error messages, screenshots '
              'or device identifiers.',
            ),
            value: _includeDiagnostics,
            onChanged: _busy
                ? null
                : (value) => setState(() => _includeDiagnostics = value!),
          ),
          if (_includeDiagnostics && _diagnostics?.storageError != null)
            Text(
              _diagnostics!.storageError!,
              key: const ValueKey('report-diagnostics-error'),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('report-preview'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy ? null : _prepare,
            icon: const Icon(Icons.preview_outlined),
            label: Text(
              _busy
                  ? 'తెరుస్తున్నాం / Preparing…'
                  : 'నివేదిక చూడండి / Preview report',
            ),
          ),
        ] else ...[
          Text(
            'పంపే సమాచారం / What you will share',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('report-content'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: SelectableText(_preview!.text),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              key: const ValueKey('report-share'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy ? null : () => _share(buttonContext),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('షేర్ చేయండి / Share report'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('report-edit'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy
                ? null
                : () => setState(() {
                    _preview = null;
                    _message = null;
                  }),
            child: const Text('సవరించండి / Edit report'),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(_message!, key: const ValueKey('report-status')),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'ఏదీ స్వయంగా పంపబడదు.\n'
          'Nothing uploads automatically. Share opens your device’s menu; '
          'choose the developer’s contact or the person helping you. '
          'This app has no support inbox. A temporary report file may remain '
          'in sharing caches. Clearing history does not remove shared copies.',
        ),
      ],
    ),
  );
}
