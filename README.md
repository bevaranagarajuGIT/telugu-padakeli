# Telugu Padakeli

A Flutter starter app for Telugu word games and learning, designed for children
and older adults. Android and iOS platform projects are included.

## What Works

- Tirumala-inspired illustrated splash and a Telugu family welcome screen.
- First-launch onboarding with Skip and Start actions; completion is saved locally
  so returning users open Home directly.
- Responsive home screen with the Telugu title, Classic Padakeli, Kids Learning
  Games, Daily Puzzle, and My Progress cards.
- Classic connected Telugu sample crosswords with clues, answer checking, and reset.
- Kids missing-letter game with retries and one point per correctly answered
  question.
- Telugu-first Kids dashboard with three freely selectable learning paths,
  five activity types, optional English Helper and session-only completion stars.
- Font-size and dark-mode settings through the home screen's settings button.
- A gentle home entrance animation that respects system reduced-motion settings.
- Locally bundled Telugu and Latin fonts. No runtime font downloads, account,
  analytics, advertising, or backend service is needed.

Daily Puzzle and My Progress are explicitly marked as coming soon. This starter
does not yet persist settings or scores, track streaks, or provide online content.

## UI V2: Phase A

Phase A uses the approved written blue/purple/orange/teal/pink direction; no
separate reference image was supplied. The Home artwork milestone now replaces
the code-drawn header/feature art with bundled original PNG illustrations.
No network images or fonts are required.

The four home actions are Classic Padakeli, Play & Learn, Daily Puzzle, and My
Progress. Bottom navigation offers Home, Classic, Learn, and Progress. Android
Back returns from a destination to Home. Classic includes Beginner and Easy puzzles, clue selection, an akshara palette,
and hints. Kids mode includes five levels with three multiple-choice questions
each. Puzzle data is validated on loading, with a Retry action if loading fails.

The Classic selector follows the colourful level-card reference: a blue backdrop,
Telugu-first labels, and locally drawn sprout/star/mountain/crown emblems. Beginner
and Easy open the existing puzzles; Medium, Hard, and Expert remain visibly locked
and marked Coming Soon. Cards expand and scroll for larger font settings, support
keyboard selection and dark mode, and provide a Back to Home action.

Classic includes three puzzles each for Beginner and Easy. Check Answer validates
the entire grid; a correct solution shows feedback for 1.1 seconds, then opens the
next puzzle in the same difficulty with a fresh grid and clue selection. The last
puzzle opens a level-complete screen with Replay and level-selection actions.
Reset, changing difficulty, and disposal cancel pending progression.
The compact blue-framed board uses yellow active cells and Across/Down clue tabs,
with each clue shown once and the normal-phone actions above bottom navigation. Its
blocked cells use lavender tiles with locally drawn four-petal rangoli motifs;
they remain non-interactive and excluded from accessibility navigation. The
colourful, scrollable Hints sheet offers authored simpler clues, first-unsolved
akshara reveal, and one-cell reveal without adding coins or paid hints. Large-font boards can
scroll horizontally rather than shrinking text or tap targets.

Play & Learn uses a Template B-inspired purple/lavender layout, rounded answer
tiles, question progress, and a hint scene with the bundled original learning
cards and parrot. It preserves all five levels, retry/scoring rules, and automatic
advance; the reference's hearts do not introduce a lives mechanic. The Back
action returns Home without discarding in-session answers. Enlarged text uses a
scrollable single-column layout, and dark mode preserves the same controls.

Continue Playing retains the current classic puzzle while switching tabs within
the same app session. It does not claim saved progress after closing the app.
The daily feature is explicitly Coming Soon, with a working sample-puzzle action.
My Progress remains the existing honest placeholder until Phase E.

Typography offers normal (1x), large (1.2x), and extra-large (1.4x) app sizes,
on top of the system's accessibility scaling. Navigation labels adapt to icon
destinations with accessible labels/tooltips at extreme text sizes.
Material text geometry is resolved before applying the app preset, including
navigation and primary text roles. The system `TextScaler` remains independent,
including nonlinear scaling. Settings-to-Home regressions check actual rendered
font sizes, text growth, large-preset single-column cards, and return to normal
rows in light and dark mode.

Phase A code:

- `lib/app/theme/app_colors.dart`: centralized brand palette and contrast-safe ink.
- `lib/core/app_theme.dart`: light/dark Material themes and typography roles.
- `lib/app/navigation/app_shell.dart`: lazy tabs and in-session game preservation.
- `lib/shared/widgets/`: header, feature card, buttons, and bottom navigation.
- `lib/screens/home_screen.dart`: responsive home and honest future-feature states.
- `test/phase_a_theme_test.dart`: contrast, font presets, and navigation scaling.

Persistent progress/settings, achievements, sound, new kids games, and the
remaining reusable components are not part of Phase A.

## Classic: Phase B

The existing offline repository, Classic screen, numbered board, rangoli blocks,
palette, clue tabs, difficulty cards and automatic progression are reused. The
approved Splash, Welcome, Home and Kids implementations are unchanged.

- Cells contain complete Telugu orthographic syllables, not code points or
  generic grapheme clusters. Guninthalu, virama-linked consonant clusters,
  anusvara/visarga and conjunct rendering joiners are handled explicitly.
- Telugu's canonically decomposable AI vowel sign is normalized for comparison;
  ZWJ/ZWNJ rendering variants of valid conjuncts compare equally. This is a
  Telugu-specific comparison, not a general-purpose Unicode normalizer.
- Validation checks individual aksharas, answer-to-cell boundaries, crossing
  agreement, numbering, coverage of every multi-cell word, grid connectivity,
  supported difficulty and unique puzzle IDs.
- Tap a word's clue to select it. Tap the active crossing cell again to switch
  Across/Down without changing the active cell. Palette input advances along the
  selected word. Clear removes the active cell; Backspace removes it or moves
  back and clears the preceding cell when it is already empty. Selected-word
  reset also clears its shared intersections.
- The displayed percentage is **filled cells**, not a claim that answers are
  correct. Check validates the whole puzzle; wrong filled cells receive an error
  icon, border and Telugu accessibility announcement. Editing clears the edited
  cell's stale error. Correct grids retain the approved 1.1-second feedback and
  automatic progression, with a static celebration that requires no motion.
- Hints reveal the first unsolved cell in reading order, reveal one unsolved
  active cell (or the next unsolved cell in the selected word), or display a
  manually authored simpler clue when available. They never overwrite correct
  cells or reveal an entire word at once. Successful hint actions are counted
  per puzzle attempt; a full confirmed reset clears that count.
- Full reset requires confirmation. Opening its dialog pauses pending automatic
  progression; cancelling resumes it, and confirming cancels it and clears the
  current board. No timer can advance the board behind the reset dialog.
- Only validated, bundled levels are enabled. All five cards are data-driven;
  Medium, Hard and Expert remain Coming Soon with the current six samples.
- Larger grids and large-font boards can be scrolled horizontally without
  reducing akshara size or 48-pixel cell targets. Other game content scrolls
  vertically. No new dependencies or online services were introduced.

### Content audit and release review

All six existing original sample puzzles are explicitly marked
`pending-human-review` in JSON. Technical validation is not linguistic approval.
The 13 answers have no duplicate normalized spellings. The tautological Easy
clue that repeated its answer was replaced with an original candidate wording;
that wording and its hint still require Telugu editorial review.

| Puzzle ID | Level | Answers requiring review |
|---|---|---|
| 1 | Beginner | ఆట, శంఖం, ఆకాశం |
| 2 | Easy | కథ, కలం |
| 3 | Beginner | అమ్మ, అరటి |
| 4 | Beginner | ఇల్లు, ఇనుము |
| 5 | Easy | తామర, తాళం |
| 6 | Easy | పరుగు, పలక |

A fluent Andhra Pradesh/Telangana Telugu editor should review spelling,
orthographic cell boundaries, natural clue wording, meanings, regional
inclusivity and difficulty. These small 3x3 teaching samples are not a finished
newspaper-size content pack. No copied newspaper/textbook exercises or additional
unreviewed candidate puzzles were added. Broader cultural, geography, proverb
and literature categories need original, human-reviewed content in Phase C.
Game state and hint counts remain in-session only; durable resume is future work.

## Kids Learning: Phase C

The Learn tab now opens a Telugu-first activity dashboard, extending the approved
Template B purple/gold design with the existing local cards and parrot. Classic,
Splash, Welcome, Home artwork and crossword parsing remain unchanged.

| Learning path | Suggested ages | Available activities |
| --- | --- | --- |
| చిన్నారులు | 3-5 | Picture matching, letter recognition |
| బాల మిత్రులు | 6-8 | Letter recognition, complete the word, word builder |
| పద వీరులు | 9-12 | Complete the word, word builder, meaning match |

These are freely selectable educational paths, not verified ages. No name,
birthday, account, advertising, analytics, network service or new dependency is
introduced. Sessions contain two to five questions. Picture/letter choices give
immediate feedback; other games use an explicit Check action. Correct responses
lock to prevent duplicate scoring; Next keeps feedback visible until the child
is ready. Incorrect responses can be retried without losing points.

The two missing-akshara activities adapt Beginner and Medium questions from
`KidsQuestionService`, rather than replacing the original content. The dashboard's
**మునుపటి అక్షరాభ్యాసం** action preserves all five original levels, automatic
advancement and in-session answers. Activity sessions, selected category and the
original practice survive switching Home/Learn tabs. Leaving an unfinished
activity and reopening it resumes the same in-session attempt.

Word builder uses the Phase B `TeluguAkshara` parser and canonical equivalence.
Tiles have individual identities, including repeated aksharas in కలకల.
Selected tiles can be removed individually, undone or cleared. Partial answers
and incorrect orders cannot succeed. Restart clears only that activity attempt.

One completed activity earns one star per app session, not one star per answer
or replay. Shared activities retain their reward when switching age categories;
replaying cannot inflate the total. The dashboard displays actual completed
questions, and completion provides Replay/Return actions without a lives system.
Celebration is static, so reduced motion never blocks feedback.

**ఇంగ్లీష్ సహాయం — English Helper** is OFF by default. The existing Provider
settings controller updates local translations immediately. English instructions,
choice translations and explanations are smaller and below Telugu; they never
replace it. Meaning explanations appear only after a correct answer. The setting,
category, attempts and stars are **in-session only**, like the existing font/dark
settings; restarting the app resets them. Onboarding persistence is unchanged.

### Files and content review

- `lib/models/kids_learning.dart`: typed activities/questions, categories,
  bilingual choices, difficulty/review status, picture descriptions and validation.
- `lib/services/kids_learning_service.dart`: six short activity packs covering
  five types, 19 original/adapted questions and authored offline English helpers.
- `lib/core/kids_learning_controller.dart`: testable attempts, tile identity,
  answer locks, progression and duplicate-safe session rewards.
- `lib/screens/kids_learning_screen.dart` and `kids_activity_screen.dart`:
  responsive dashboard/gameplay, settings access and session navigation.
- `lib/widgets/kids_learning_text.dart`: Telugu-primary/optional-English rendering.
- Existing settings, AppShell and original Kids screen integrate these surfaces.
  `pubspec.yaml` adds only a local asset directory; dependencies are unchanged.
- `test/kids_learning_test.dart` and `kids_learning_ui_test.dart`: content,
  settings, gameplay, rewards, bundled pictures, navigation and real-font layouts.
  Existing Kids/integration tests retain their original gameplay assertions with
  updated dashboard entry and Telugu labels.

**All 19 questions remain `pending-human-review`.** Runtime validation checks
unique IDs, valid choices, answer/tile agreement, complete akshara boundaries and
required fields; it cannot approve spelling, English accuracy, age suitability or
distractor/image alignment. A Telugu educator should review:

| Pack | Content awaiting review |
| --- | --- |
| Pictures (2) | మామిడి, చిలుక, distractors and picture descriptions |
| Letters (3) | అ–అరటి, ఆ–ఆవు, క–కలం and English vocabulary |
| Word completion (6) | కమలం, అమ్మ, పాఠశాల, మామిడి, పశువు, చెట్టు |
| Builder (5) | మామిడి, అమ్మ, పాప, మామ, కలకల and authored clues |
| Meanings (3) | ధైర్యం/సాహసం, ఆనందం/సంతోషం, వెలుగు/చీకటి |

Picture matching is intentionally limited to two genuine bundled illustrations:
the existing parrot and a mango-only crop of approved original `home/learn.png`.
See `assets/artwork/README.md` for provenance and distribution-review limits.
No downloaded stock images or disguised placeholder artwork is used. A larger
reviewed pack needs original/licensed fruit, animal and familiar-object pictures;
broader letters, guninthalu, vegetables, colors, geography and culture need
additional reviewed content, not automatically generated filler.

### Offline pronunciation extension

`KidsLearningQuestion.audioAsset` is an optional extension point and currently
null for every question. No audio button or pronunciation claim is displayed.
Future work must bundle educator-reviewed Telugu recordings, add an offline
player and visual alternatives, and expose controls only for playable recordings.
There is no online speech API or synthesized Telugu pronunciation.

Phase D should prioritize educator/content review, physical Android/iOS testing,
reviewed illustration/audio packs and durable local preferences/resume before
adding more levels. Native iOS signing/testing still requires macOS/Xcode or a
configured macOS build service; Flutter tests do not establish iPhone behavior.

## Splash and Welcome

The launch gate displays the branded splash while reading the local onboarding
flag and, for new users, preparing the bundled opening illustrations. There is
no artificial loading timer. One approved welcome page has one honest page
indicator. Both **Skip** and **ప్రారంభిద్దాం** save
`onboarding_completed_v1` using `shared_preferences` before opening the existing
Home/navigation shell. Save failures keep Welcome open with a retryable message;
initialization failures expose Retry rather than silently bypassing onboarding.
Uninstalling or clearing this app's data resets completion. Settings, scores,
and game progress remain in-memory; this does not add authentication or Firebase.

Telugu copy is real bundled-font text, not baked into images. Artwork keeps its
aspect ratio; content scrolls on small screens and at large accessibility sizes.
The reference-led composition blends the temple artwork into a continuous blue
sky, with mango/marigold garlands and a curved cream-and-gold splash footer.
Welcome enlarges the family scene above a compact cream panel, floral divider
and golden action, without the previous large gap between the copy and button.
The short entrance fade and loading indicators respect reduced motion. Android's
native launch bridge uses royal blue and the puzzle mark, including Android 12+
system splash support. Android 12+ removes its launch overlay as soon as Flutter
is ready instead of fading over the illustrated Flutter splash. Startup waits
for an actually rasterized engine frame before starting image preparation and
the 350 ms entrance fade, rather than consuming the animation behind Android's
launch overlay. There is no separate loading timer. Reduced motion removes the
animation wait.
iOS uses the same launch background before Flutter paints.
iOS build/runtime verification still requires macOS and Xcode.

The temple and fictional multigenerational family are newly generated stylized
illustrations based on a licensed Tirumala architectural photo. Attribution,
CC BY-SA 4.0 adaptation terms, provenance, and release-review caveats are bundled
in `assets/artwork/opening/ATTRIBUTION.txt` and available through Welcome's artwork
credits action. **Human Tirumala architectural/authenticity review and generation
service-terms review are required before release.** These images are not an
official TTD endorsement or architectural certification.

## Original Home artwork milestone

Home includes an illustrated orchard/lotus scene, two consistent original parrot
poses, and matching Classic, Play & Learn, Daily, and Progress illustrations.
Equal-height feature rows at normal sizes, content-driven large-text layouts,
Continue Playing, keyboard/semantic activation, local typography, and existing
gameplay are preserved. Daily and Progress remain Coming Soon.

The parrot's restrained movement is a bob of static raster artwork, not
expressive character animation. Repeating motion is explicitly gated by the
selected Home tab, Settings visibility, app lifecycle, and reduced motion.
See [the artwork manifest](assets/artwork/README.md) for generation briefs,
source/provenance, transparency requirements, and unresolved license-term review.
The named external reference screenshots were not supplied to this checkout.

GitHub Actions uses Flutter 3.44.2 and runs formatting, analysis, tests (including
asset decoding/alpha and hidden-screen motion regressions), and an
offline-resource web build on PRs.
Its `web-preview` artifact can be served locally for actual runtime review;
it is a runnable app build, not a generated UI mockup. Native-device review is
still required before release.

## Open in VS Code

Select **File > Open Folder** and choose `C:\Projects\telugu_padakeli`.
The Flutter and Dart extensions are installed. This workspace's
`.vscode/settings.json` points to `Q:\tools\flutter`.

Open a PowerShell terminal:

```powershell
Set-Location C:\Projects\telugu_padakeli
flutter doctor
flutter pub get
flutter analyze
flutter test
```

## Run on Android

Start the configured emulator if it is not already running:

```powershell
flutter emulators --launch TeluguPadakeli_API36
flutter devices
```

Once an Android device appears, run:

```powershell
flutter run -d emulator-5554
```

Use the actual device ID from `flutter devices` if it differs. Alternatively,
select the Android device in VS Code's status bar and press **F5**.

In the terminal, `r` hot reloads, `R` hot restarts, and `q` stops the app. A cold
emulator boot and the first Gradle build can take several minutes.

The emulator uses Windows Hypervisor Platform, which was already available.
Flutter uses Android Studio's bundled JDK; no separate Java installation or
permanent `JAVA_HOME`, Android PATH, or virtualization change was needed.
The first Android build also downloaded CMake 3.22.1 into the Android SDK as a
native build dependency. Existing Flutter, Dart, Git, Java, and Android Studio
installations were reused rather than reinstalled.

## Browser Preview

The web target runs the same shared Flutter app without an Android emulator.
For interactive development:

```powershell
Set-Location C:\Projects\telugu_padakeli
flutter run -d chrome
```

For a local release preview with the renderer and fonts served locally:

```powershell
flutter build web --no-pub --no-web-resources-cdn
python -m http.server 52642 --bind 127.0.0.1 --directory build\web
```

Open `http://127.0.0.1:52642`. Rebuild after Dart changes when using the release
preview. Browser checks do not replace testing native keyboards, Android Back,
or real Android/iOS device behavior.

## iOS on macOS

Windows can edit the shared Dart code and generate the iOS project, but cannot
run Xcode, the iOS simulator, or sign/build an iOS application.

On a Mac with Xcode and the required Apple tooling:

```sh
flutter doctor
flutter pub get
flutter devices
flutter run -d <ios-device-id>
```

Follow `flutter doctor` for any missing Apple dependencies. Configure the signing
team and a unique bundle identifier in Xcode before publishing.

## Code Map

- `lib/main.dart`: app startup, license registration, and settings provider.
- `lib/core/`: Material themes and in-memory settings.
- `lib/screens/home_screen.dart`: responsive dashboard and accessible card actions.
- `lib/screens/`: classic game, kids game, settings, and progress placeholder.
- `lib/widgets/premium_telugu_text.dart`: wrapping, system-scaled Telugu text.
- `assets/data/`: local sample crossword.
- `assets/fonts/`: Noto Sans Telugu and Roboto at weights 400, 500, and 700, with
  their original SIL OFL and Apache 2.0 licenses.
- `test/`: navigation, scoring, real-font asset, and accessible text-scale tests.

Cards have content-driven heights, large touch targets, and scroll when text
grows. Telugu layout tests cover 320–1280 logical-pixel widths, light/dark themes,
and up to 3.2x system scaling with the largest app font setting. Do not put
`PremiumTeluguText` in a fixed-height or clipping parent.

## Before Publishing

The Android application ID and iOS bundle identifier currently use the
development placeholder `com.example.telugu_padakeli`. Choose your own identifiers
and configure production signing. The Android release template currently uses
development signing and is not store-ready.

Validate on real Android and iOS hardware, including large-text accessibility and
screen readers. Replace and validate the sample puzzle content before release.
No iOS build or App Store readiness is implied by generating the iOS folder.

## Current game content

Classic has two connected 3x3 samples. Each cell contains a complete Telugu
akshara and belongs to a clue. Medium, Hard, and Expert Classic puzzles remain
coming soon. Kids mode has 15 questions across five levels, a final score, and
a restart action. Settings, scores, and puzzle progress remain in memory only.
