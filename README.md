# Telugu Padakeli

An offline, Telugu-first Flutter learning and crossword app for children,
families, students and older adults. No account, analytics, ads, live AI,
speech recognition, runtime font download or backend is required.

## Current features

- Tirumala opening on every fresh launch; family Welcome appears once. Warm
  resume preserves the current screen. Existing illustration credits remain.
- Home prioritizes Classic, Kids and a real saved Resume action. Daily Puzzle
  and My Progress are compact secondary destinations, not placeholders.
- Classic has a validated local pack across all five difficulties. Complete
  Telugu aksharas occupy cells; crossings, numbering, coverage and connectivity
  are checked before play. Across/Down clue selection, a letter palette, selected
  word editing, authored hints, one-cell reveals and confirmed reset remain.
  Correct checks advance within a level after 1.1 seconds; changing level is
  explicit. Filled-cell percentage is not an accuracy claim.
  Clear letter, Backspace and Clear word use distinct tonal icon buttons with
  brief press feedback, equal normal-text targets and a large-text stacked
  layout. Reduced motion disables the press animation; editing behavior is
  unchanged.
- Kids offers three freely selectable Telugu-first learning paths: చిన్నారులు,
  బాల మిత్రులు and పద వీరులు. Picture, letter, missing-akshara, word-builder and
  meaning games retain retries and explicit continuation. Original practice is
  also available, with its original questions and automatic progression intact.
  These suggested paths are not verified age assessments.
- A correct answer exposes Next/Finish in a separate adaptive SafeArea footer.
  Scrolling answers/explanations never sits underneath it. Completion resets
  scroll position, focuses and announces its heading, keeps Hanuman visible,
  pins the main continuation, and leaves Replay/Return in the scrollable result.
- English Helper adds translations beneath Telugu. Navigation/action controls
  remain bilingual regardless of Helper. Normal, large and extra-large app fonts
  compose with independent system text scaling. Light/dark themes, keyboard
  controls, accessible labels and reduced motion are preserved.
- Brief press/correct/retry feedback and the original articulated Flutter
  Hanuman celebration are presentation only. Inputs are immediately usable;
  animation stops when covered, hidden or backgrounded. Restored results are
  static, with no stale reward flight or sound.

## Saved data and recovery

`LearningProgress` owns versioned local state through the injectable
`LearningStore` interface. Production uses the existing `shared_preferences`
dependency; tests use an in-memory implementation. No dependency was added.

The `padakeli.learning.v1` record contains settings (font, theme, Helper, sound,
daily goal), Kids category/current attempts/solved IDs, original-practice state,
Classic and date-specific Daily boards, answer records, completions, rewards and
achievements. Classic restores puzzle/difficulty, cells, selected direction/clue/
cell, hints and completion. Writes debounce for 250ms, serialize snapshots in
order, and flush when the app becomes inactive/backgrounded.

Stable IDs plus exact content signatures prevent old answers from being applied
to changed content. Kids keeps unchanged solved questions and returns to the
first changed/unsolved question. A changed Classic board starts fresh while other
progress is retained. A changed original-practice pack restarts that attempt;
historical rewards/records remain. Reopening never grants another reward.

Missing saves start clean. Unreadable JSON/schema sections are preserved once at
`padakeli.learning.v1.recovery`, with a visible notice. Unsupported versions and
failed reads block writes rather than overwriting unknown data. Write failure
keeps play responsive and exposes Retry saving in Settings. Read failure asks
for an app restart. Reset requires an explicit confirmation, clears learning
state/rewards/Daily boards and removes stale screens, but preserves preferences
and the separate completed-Welcome flag.

This is device-local convenience storage, **not** encrypted storage, a cloud
backup or a guaranteed transactional database. Abrupt process termination before
a pending write completes can lose the most recent change. Uninstalling or
clearing application data removes progress.

## My Progress: metric definitions

The dashboard uses saved events, never sample numbers or online rankings.
Today’s goal has a dedicated summary with the actual correct-question count
even after the goal is exceeded. Resume appears beside the learning summary,
followed by responsive all-time statistics, first-check results, learning paths
and earned/unearned achievements. Metric definitions are available in the
expandable “How progress is counted” section; the device-local storage notice
remains visible. Large text stacks the statistics without truncating labels.
Activities, puzzles, stars and streaks have blue, mint, gold and warm-orange
KPI backgrounds; first-check results use lavender. Each palette adapts to dark
mode and retains text labels, so colour is never the only way to identify a metric.
Learning paths use distinct mint, blue and lavender surfaces with matching
progress bars and a tonal Explore action; their counts still require
content-valid saved completions, not inferred mastery.

| Metric | Definition |
|---|---|
| Daily goal | Configurable 1–10 distinct correctly answered Kids/practice question versions per local day; default 3 |
| Today | Distinct correct question versions and completed activity IDs that day; repeats do not multiply them |
| Completed activities | Distinct Kids or original-practice level IDs ever completed |
| Classic puzzles | Distinct Classic content IDs completed, including those played in Daily |
| Earned stars | One per activity ID, one per Classic puzzle ID, and one per Daily date; replay is not another star |
| First-check correctness | First-ever submitted check for each unchanged Kids/practice question; a later retry cannot repair its first result |
| Submitted checks | Actual nonempty submitted attempts, not taps, impressions or unique vocabulary |
| Eventually correct | Question versions with a correct check, separately from first-check correctness |
| Path completion | Currently saved, completed packs whose solved-question signatures still match current content |
| Current/best streak | Consecutive local calendar days with a correct answer or activity/crossword completion; today may be empty if yesterday continues the run |

Achievements are First activity, First crossword, 10 first-check correct
questions and 3 consecutive learning days. Each is stored once. No answered word
is labelled mastered. Empty states avoid estimated accuracy and division by zero.
Resume reopens the most recently saved activity/practice/Classic/Daily attempt;
Explore allows revisiting all freely available activities.

Calendar arithmetic uses the ordinal of local year/month/day, not elapsed
24-hour periods. A forward jump can break a streak; backward-clock future
records are retained but excluded until their date returns. There is no trusted
online clock: changing device date/time zone can change which local date applies,
but cannot award the same stored reward key twice.

## Honest offline Daily Puzzle

Daily reuses the Classic solver. For a new date it sorts bundled IDs and selects
`daysFrom2026Jan01 mod packLength`, then stores that date and ID. Reordering the
pack does not replace a saved choice; missing saved content shows a retryable load
error rather than silently switching puzzles. Each date has its own saved cells
and completion, and its completion reward is once per date.

The finite local pack repeats. The UI discloses its rotating size and labels dates
outside the first cycle **Practice repeat**; it does not promise unlimited unique
boards. At midnight or foreground resume, an open old board is labelled as a saved
past date. It remains playable; return Home to open today's board. Completing it
qualifies the actual day of learning, not an unplayed date.

## Content, artwork and unavailable audio

`assets/data/content_review.json` is the editable review inventory for every
Kids, original-practice and Classic clue. It includes stable ID, category/
difficulty, prompt, answer, distractors, explanation, English, picture/audio
references, exact recording script, status and reviewer notes. Repeated vocabulary
is grouped explicitly; shared practice is not new unique-word growth.

Regenerate after source edits:

```powershell
dart run tool\export_content_review.dart
```

Reviewer notes survive by ID. Approval status survives only if the exact content
is unchanged. Automated structural/akshara/answer checks are **not** Telugu
educator approval. All current entries remain `pending-human-review`; a fluent
Telugu educator must review natural wording, translations, plausible distractors,
regional inclusivity and difficulty. No filler questions were added.

The user-approved original nine-object illustration sheet supplies consistently
padded PNG vocabulary assets; the standalone parrot replaces the mixed-scene
picture. Picture questions use the newer standalone `mango-v2.png` from the
layout refinement, documented in `assets/artwork/kids/mango-v2.md`. The sheet
mango and other objects remain prepared artwork, not extra exercises.
Images use `BoxFit.contain` and accurate text descriptions. No Telugu lettering
is baked into images. See `assets/artwork/kids/ATTRIBUTION.txt` and
`assets/artwork/README.md` for provenance, generation and distribution limits.
The existing Hanuman remains original Flutter vector art, not finished 3D art;
its style is not identical to the new storybook vocabulary set. Final human
art/cultural/rights review remains necessary.

**No approved offline audio is available.** The existing audio manager is silent,
with navigation/background/preference cancellation ready for a reviewed backend.
Pronunciation actions stay hidden when files are absent. The saved reward-sound
preference explicitly says playback is unavailable. The content inventory supplies
recording scripts and null file references. Native-speaker recordings, consent,
licenses, pronunciation and levels must be approved before adding real playback;
there is no speech-recognition or audio-dependency substitute.

## Official reference comparison

Sources retrieved 2026-11-10. These are verified product/store descriptions, not
hands-on app/animation observations or independent proof of learning outcomes.
The final column is this project's interpretation, not a quoted source feature.

| Official source | Verified description | Application here |
|---|---|---|
| [Learn Telugu Language Offline](https://play.google.com/store/apps/details?id=com.eduven.ld.lang.telugu&hl=en-GB) | Image/audio/phonetic vocabulary, named categories, saved learning and revision games | Recognizable isolated pictures, descriptive Telugu paths and an editable recording manifest; no unapproved audio |
| [Shoonya Telugu](https://www.shoonyadigital.com/telugu) | Foundational game-based language learning and heritage/cultural context | Preserve Telugu identity and varied child-sized rounds; no curriculum-approval claim |
| [Ling Telugu](https://ling-app.com/learn-language/telugu/) | Native-audio, vocabulary and conversation lessons with game-based challenges | Short, varied activities with Telugu-first instructions; not copied exercises or promised native audio |
| [Google Read Along](https://readalong.google/) | Reading encouragement through stars/badges, offline-capable mobile use and Classroom progress insights | Modest once-earned encouragement and clearly defined local progress; no microphone, AI or teacher-service integration |
| [Telugu Words Game – PadaKeli](https://play.google.com/store/apps/details?id=tech.ttalks.TeluguWordsGame&hl=en) | Telugu word puzzles, multiple levels and simple controls | Calm controls and distinct difficulty; its listing did **not** verify clue-based crosswords or resumable play, so those are our own requirements |

No competitor illustrations, logos, wording, scores, purchase locks or wholesale
layouts were copied. Meowdoku was a personality reference only, not a feature,
dependency or surveyed animation source.

## Develop and validate

Use the existing Flutter/Dart installation and platform tooling:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub --no-web-resources-cdn
flutter build apk --debug --no-pub
flutter run -d emulator-5554
```

`test/kids_visibility_test.dart` checks actual rectangles/hit testing at 320/390
widths, 480/568 heights, normal/extra-large app text, both themes, reduced motion
on/off and English Helper on. It taps Next/Finish without scrolling, checks the
heading/whole character inside completion's viewport, scrolls explanations above
the footer, verifies heading focus and reaches Replay/Return. Existing suites
also cover extreme system text, gameplay, aksharas, accessibility and motion.
Saved-game tests recreate screens with reloaded storage, including Classic hints/
selection, original-practice score, Daily replay/rollover and reset confirmation.

For release-web preview, serve `build\web` locally; all resources stay local:

```powershell
python -m http.server 52642 --bind 127.0.0.1 --directory build\web
```

Windows cannot build/sign iOS or run VoiceOver. Android emulator results do not
replace real-device/TalkBack testing. The development application identifiers
and debug signing are not store-ready. Existing emulator native access-violation
crashes remain an environment limitation, not a proven permanent app fix.

## Code map

- `lib/core/learning_progress.dart`: versioned saved state, metrics and writes.
- `lib/services/learning_store.dart`: production/test storage implementations.
- `lib/core/kids_learning_controller.dart`: signature-aware Kids attempts/rewards.
- `lib/services/daily_puzzle_service.dart`: deterministic, saved Daily choice.
- `lib/screens/`: Home, Classic/Daily, Kids, Progress and Settings.
- `lib/widgets/`: grid, footer, Telugu text, motion and character.
- `assets/data/`: offline puzzles and editable review inventory.
- `assets/artwork/`: original illustrations and required attribution.
- `assets/fonts/`: locally bundled Noto Sans Telugu (SIL OFL) and Roboto (Apache 2).
- `tool/`: content-review export, image preparation and existing icon tooling.
