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
colourful, scrollable Hints sheet preserves basic hints, first-akshara reveal,
and whole-word reveal without adding coins or paid hints. Large-font boards can
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
