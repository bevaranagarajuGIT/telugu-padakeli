# Friends release stabilization report

## Recommendation

**Ready for a small Android friends beta using the tested APK.** No remaining
release blocker was reproduced within the coverage below. Automated checks,
native recovery tests and the final non-debuggable release-install walkthrough
pass. This is not a Play Store production release or a guarantee that every
device and input combination is bug-free.

## Branch and feature audit

The stabilization branch is `stabilization/friends-release`, created from
`6b93f6c799553a2655d5baf43c9106578d918b81`, the freshly fetched release baseline.
Before publishing, `origin/main` and `origin/master` still point to that same
commit. Neither release branch was changed.

`9c45a0d5ebaf20ca612cd0c7c529941ceba38c62` is an ancestor of both release
branches. Its Home hierarchy/Resume, compact Kids welcome, pinned quiz actions,
scroll/focus resets, mango replacement and regression tests remain in the
actual source. The mango bytes match that commit.

All fetched feature branches are already ancestors of `origin/main`:
`bevaranagarajugit-fix-font-geometry`, `bevaranagarajugit-fuzzy-carnival`,
`compact-home-hero-preview`, `feature/classic-edit-controls` and
`feature/offline-learning-progress`. PRs #1, #2 and #3 are merged. The offline
milestone reconciliation at `a6fab943` and the later Classic controls/colored
Progress work at `6b93f6c` are present. No missing commits or competing
implementations required integration. No existing work was discarded.

## Reproduced bugs and fixes

| Bug and reproduction | Cause | Surgical fix and regression evidence |
|---|---|---|
| Save a valid board/reward, then change a top-level section such as `settings` to `null` and relaunch. Other valid progress disappears. | One malformed section rejected the entire version-1 record. | Back up the entire original first, replace only unreadable sections, and retain readable sections and unknown metadata. Six storage regressions initially failed; memory and mocked-preferences recovery cases now pass. Actual Android injected-section recovery retained sessions, boards, answers, rewards and practice exactly. |
| Preserve one damaged save, then encounter a different damaged save. | An existing recovery copy was treated as successful preservation even when it contained different data. | Identical copies are idempotent; a different copy/type blocks writes. Both originals remain intact. Automated and native conflict checks verify byte-for-byte preservation. |
| Enter letters/use a hint, choose another Classic difficulty, then return or reselect the same difficulty. | Difficulty selection opened a fresh first board and overwrote the only Classic slot. | Keep one current board per difficulty while retaining the latest-board Home Resume alias. Both new widget regressions failed before the fix. Actual Android switched through all five difficulties and retained the original Beginner board, selection and hint. |
| Remove/corrupt reward identities while retaining completed activities, then complete/replay an activity. | An empty replacement ledger could allow previously earned rewards to be issued again. | Preserve the source and expose readable progress, but block saving and all new star awards until recovery or explicit reset. A missing ledger with existing completions is also protected. All four new memory/preferences regressions failed before the fix and now pass. Missing sections in a genuinely new save remain supported. |
| Complete an activity at 320 x 480, extra-large app text, dark theme and English Helper. The character is cut off above the pinned footer. | The compact scene's minimum height omitted the actual Android status-bar inset. | Account for the top inset without shrinking text or touch targets. The existing 64-case visibility matrix now includes 28px top/24px bottom system insets; its strict full-character assertion failed before the fix. Native before/after screenshots confirm the entire character and heading are visible. |

No dependency, app redesign, content-pack expansion or signing reconfiguration
was introduced. Tests also now use the real Welcome-completion preference key,
so onboarding/reset assertions exercise the actual flag.

## What survives and what does not

The app already used real SharedPreferences, rather than session-only progress.
The versioned `padakeli.learning.v1` record stores settings, Kids attempts/solved
question identities, completed activities, reward identities, answer statistics,
daily activity records, achievements, original-practice state, Classic boards
and date-specific Daily boards.

Classic preserves puzzle identity, entered aksharas, selected direction/clue/
cell, used hints and completion. Each difficulty now retains its own current
board. Existing version-1 saves without the new difficulty slots remain
compatible. Home Resume still chooses the most recent destination.

Kids completion history/stars survive replay, navigation and relaunch. An active
replay can be incomplete while its previously earned star remains. Completing it
again does not add another star. Welcome completion is stored separately at
`onboarding_completed_v1`; normal update installation does not restart onboarding.

Writes are debounced by 250ms, ordered and flushed when inactive/backgrounded.
Native force-stop/relaunch, an explicit app-process kill after backgrounding,
and APK installation with `-r` retained committed progress and preferences.
The process-kill exercise is **not** evidence of every Android low-memory-killer
or power-loss situation. Killing the process before a pending write finishes
can lose the most recent unsaved edit.

Malformed whole JSON is copied before a fresh temporary starting state is
allowed. Readable sections of a partially damaged version-1 record are retained.
A conflicting recovery copy, an unsupported older/newer version, a failed read,
or unreadable/missing reward identities with existing completions prevents
unsafe writes. A visible notice explains temporary play; blocked storage cannot
grant new stars. A normal write failure offers Retry saving in Settings.

There is **no automatic in-app backup-restoration tool**, cloud account or
backend. A protected damaged save can require support/manual recovery or an
explicitly confirmed reset. No migration of an unknown schema is guessed.
Uninstalling or clearing app data loses progress. This is not encrypted,
transactional, filesystem-corruption-proof or independently backed-up storage.
Damage to the entire Android preferences XML is outside the JSON-recovery
guarantee. Explicit reset still clears learning/rewards/all board slots while
preserving settings and Welcome completion.

## Fresh development checks

The untouched baseline was checked first: analysis clean, 432 tests passing,
both APK variants built. The final source was checked again after all fixes:

| Command | Actual final result |
|---|---|
| `flutter --version` | Flutter 3.44.2 stable; Dart 3.12.2 |
| `flutter doctor -v` | Exit 0; no issues found |
| `flutter devices` | Exit 0; both Android emulators plus Windows/Chrome/Edge detected |
| `flutter pub get` | Exit 0; no manifest/lock changes or upgrades |
| `flutter analyze` | Exit 0; no issues found |
| `flutter test --reporter compact` | Exit 0; **447 tests passed** |
| `flutter build apk --debug` | Exit 0; APK built |
| `flutter build apk --release` | Exit 0; APK built, approximately 55.5MB |

The additional 15 tests comprise 13 storage/recovery cases and two Classic
navigation cases. Existing tests were not weakened. Formatting and
`git diff --check` pass. The strengthened 64-case Kids geometry matrix covers
320/390px widths, 480/568px heights, normal/extra-large app text, both themes,
Helper and reduced-motion states, and actual system insets. It asserts visible
heading/whole character, reachable actions and footer/content separation.
These are automated widget checks, not 64 separate physical-device sessions.

No software or dependency was installed or upgraded. `pub get` advertised newer
incompatible package versions; they were intentionally not adopted.

## Actual Android walkthrough

Testing used a separate disposable Android 16/API 36 x86_64 emulator,
`TeluguPadakeli_Stabilization`. The original user emulator and its app data were
left untouched. The QA device used the already-installed system image and
software rendering. Its normal display was approximately 411 x 914 logical
pixels; overrides exercised exact 320 x 480 and 390 x 480 viewports.
The walkthrough used successive candidates; affected flows were repeated after
their fixes, followed by the final release installation and gameplay smoke.

| Flow | Actual device evidence |
|---|---|
| Fresh launch/settings | Welcome, Home, actual completion preference, theme/font/Helper and returning launch exercised. |
| All five Kids activity types | Completed picture, letter, missing-akshara, builder and meaning activities: five distinct stars. Wrong/retry feedback verified in missing-akshara and builder. Builder undo, repeated letters and compound `అమ్మ` exercised. |
| Navigation/rewards | Next/Finish, replay, Return, repeated Next and leaving activities exercised. Force-stop and simulated process death restored attempts/completions without extra stars. |
| Small screen/accessibility | Actual 320 x 480 extra-large/dark/Helper completion and actions; 390 x 480 normal/light/Helper completion and tappable Next. Full character pixels inspected, not just widget existence. |
| Classic | All five difficulty choices; original answers/hints retained; wrong validation; Across/Down and compound `కా`; exact board resume after process kill; nonempty Reset cancel/confirm; all three Beginner boards completed. Stars advanced from five to eight. Final release also restored the saved Easy letter and passed real Clear letter, Backspace and Clear word checks. Its akshara palette did not open the system keyboard. |
| Daily | Calendar-specific board identity and entered letters survived relaunch through Resume. Actual completion added one star; fully answering its replay did not add another. Classic's saved board stayed unchanged. Total: nine distinct stars. |
| Original practice | Wrong/correct selection, automatic advance and stored practice state exercised. |
| Lifecycle/offline | Background/foreground, force-stop, explicit process kill, relaunch and update-over-existing-data exercised. No active default network was verified while playing offline. Rotation retained Classic completion; portrait restored afterward. |
| Corruption/recovery | Injected partial JSON, conflicting recovery, missing/unreadable reward identities and unsupported version-0 records tested only on QA. Main record and recovery copy were compared exactly. Visible protection notices verified. `finally` restored the exact valid nine-star record. |
| Release installation | APK signature verified, installed over debug without clearing data, and confirmed non-debuggable. Cold launch retained Welcome/Home, nine stars, saved Daily completion, in-progress Meaning and an independently saved Easy letter. Normal-motion continuation and immediate system Back during correct-feedback animation passed. |

The Classic entry surface uses the app's bundled akshara palette; real compound
characters were entered through that UI. This does not claim coverage of every
third-party IME, hardware keyboard or independent OS font-size setting.

The QA emulator initially displayed an Android Bluetooth system-service crash
during first boot; Bluetooth was disabled only on that disposable emulator.
This was not a Telugu Padakeli crash. ADB fixture/selector timing failures were
corrected before accepting results; stale XML and truncated fixture writes were
not treated as app findings. Captured debug logs contained one Bluetooth fatal
and nine UIAutomator startup timeouts, all classified as system/driver failures,
not app crashes. Debug and final release logs contained no app fatal exception,
unhandled Flutter exception, layout overflow or missing-asset error in the
captured scenarios.

## Evidence and remaining limitations

The PR includes real Android before/after completion screenshots, final runtime
evidence and a 59.98-second recording from the final installed release. Full
local command logs, decoded QA saves,
assertions and additional screenshots are retained as session artifacts, not
committed device-private data.

Release packaging retains the existing application ID
`com.example.telugu_padakeli`, version `0.1.0`/code `1`, and **debug-key signing
for the release variant**. It is suitable only for controlled direct-install
testing, not Play Store publication. Update retention was tested with matching
signatures; an APK signed by a different key cannot update an existing install
in place. Production signing/versioning remains separate work. The universal APK
contains arm64-v8a, armeabi-v7a and x86_64 code and requires Android API 24 or
newer. Its verified SHA-256 is:

```text
34BAF6DF3A4023F78A75765212DD487C41F66A7E77EDA17368CC5B4167888024
```

No physical Android device, iOS, OEM-specific lifecycle policy, real low-memory
kill, power interruption, independent installed-key migration, TalkBack user
session or exhaustive device/content combination was tested. All five Kids
mechanics were completed, not every question in every content pack. Higher
Classic difficulties received actual selection/input/persistence checks, not
full completion of every board. Calendar rollover behavior has automated
coverage; changing the native device clock across midnight was not exercised.

Existing artwork is retained; the clean mango asset is present. No new asset
provenance, cultural/content review or audio pack was created. Independent
content/licensing review and the existing audio limitations remain. On the
smallest extra-large completion, the whole character is intentionally compact
so the heading and continuation stay visible.

No app can be certified bug-free from these results. Friends should treat the
APK as a limited offline Android beta, keep any important progress externally
recorded, and report their device/version and reproduction steps for failures.
