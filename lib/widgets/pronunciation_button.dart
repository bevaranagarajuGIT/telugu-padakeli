import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pronunciation_audio_manager.dart';
import 'kids_learning_text.dart';

class PronunciationButton extends StatefulWidget {
  const PronunciationButton({required this.text, super.key});

  final String text;

  @override
  State<PronunciationButton> createState() => _PronunciationButtonState();
}

class _PronunciationButtonState extends State<PronunciationButton> {
  bool _played = false;

  @override
  void didUpdateWidget(PronunciationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _played = false;
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<PronunciationAudioManager?>();
    if (audio == null || !audio.hasRecording(widget.text)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: ValueKey('pronunciation-${widget.text}'),
            onPressed: () async {
              setState(() => _played = true);
              await audio.play(
                widget.text,
                isForeground:
                    TickerMode.valuesOf(context).enabled &&
                    (ModalRoute.isCurrentOf(context) ?? true),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 56),
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(Icons.volume_up_rounded),
            label: KidsLearningText.control(
              '${_played ? 'మళ్లీ వినండి' : 'వినండి'} — ${widget.text}',
              english: '${_played ? 'Replay' : 'Listen'} — ${widget.text}',
              center: true,
            ),
          ),
          if (audio.error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                audio.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
