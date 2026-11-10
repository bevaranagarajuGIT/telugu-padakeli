# Home artwork

## Current vocabulary artwork

The old 88x126 mango crop of a learning card has been replaced. The user's
approved 2026-11-10 original nine-object generation supplies mango, parrot, book,
banana, lotus, cat, fish, pencil and elephant. Equal sheet cells are fitted into
512x512 RGBA canvases with consistent safe margins using the existing Dart image
dependency and `tool/prepare_learning_artwork.dart`. Objects are not stretched or
tightly cropped. Disconnected neighboring-object fragments are removed before
scaling, preserving the main object's connected silhouette. Mango/parrot are used in picture questions; seven reserved
objects do not inflate question or reviewed-vocabulary counts.

`kids/ATTRIBUTION.txt` records the source ID, transformation, use, missing audio
and unresolved human art/rights review. It is bundled in the application's
licenses. These are original supporting illustrations, not third-party stock,
commercially cleared final artwork or a replacement for the existing articulated
Flutter Hanuman. Existing home and opening artwork remains unchanged.

## App icon

`branding/app-icon.png` is the approved Family + Tirumala launcher artwork:
a centered `(160, 0, 960, 960)` crop of `opening/telugu-family.webp`, resized
to an opaque 1024x1024 PNG. It preserves the original family, temple and book
without generating new people or architecture. The platform applies its own
icon mask; rounded corners are not baked into the master.

The `flutter_launcher_icons` configuration in `pubspec.yaml` generates Android
legacy/adaptive icons, the iPhone/iPad/App Store catalog, and web/PWA icons.
After replacing the approved master, regenerate with:

```shell
flutter pub get
dart run tool/generate_app_icons.dart
```

Android adaptive foregrounds use a 16% inset and sky-blue background to keep
the composition visible inside launcher masks. PWA maskable icons reserve a
10% margin on each side so their central 80% content area survives masking.
The wrapper also preserves unrelated Xcode asset-catalog settings that the
upstream generator would otherwise overwrite. The master is a build-time
input, not an additional runtime Flutter asset. The existing opening-artwork
attribution is also exposed as **App icon** in the application's licenses.
The source's CC BY-SA treatment, authenticity review and unresolved
generation/distribution terms apply to these derived icons as well.

## Opening artwork

The separate `opening/` directory contains `tirumala-temple.webp` and
`telugu-family.webp`, each 1280x960 with a 4:3 aspect ratio, totalling 894,232
bytes. These are new stylized illustrations authorized by the user, not copied
from the supplied application's reference. Temple composition follows the
recognizable white Maha Dwaram, golden Ananda Nilayam vimana and forested hills
in the licensed architectural reference. Family art adds fictional grandparents,
parents, a boy and a girl sharing a blank puzzle book. Mango leaves, marigolds,
a learning book and brass lamp provide restrained festive detail.

Photographic source: **Nikhil B / Wikimedia Commons (Nikhilb239)**,
[Tirumala 090615.jpg](https://commons.wikimedia.org/wiki/File:Tirumala_090615.jpg),
licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
Both photo-derived adaptations retain that artwork license; it does not license
the app's source code. See bundled `opening/ATTRIBUTION.txt` for exact
modifications, generation IDs and attribution. Welcome exposes these credits
through Flutter's license page. No photographer or TTD endorsement is implied.
Human architectural/authenticity and generation-service terms review remain
release prerequisites. Do not treat generated architecture as verified fact.

Original PNGs were 1448x1086. Bundled WebP copies use Pillow LANCZOS resizing to
1280x960 and quality 92/method 6 encoding. They are displayed with `BoxFit.contain`,
bounded decode width and no runtime network requests. Actual Telugu titles,
description, Skip and Start labels remain accessible Flutter text. The opening
layout follows the supplied two-phone reference without inventing extra pages.

## Source and distribution limits

These are original static illustrations commissioned for this milestone through
the coordinating Copilot Chat's authorized `image_generation` PNG tool on
2026-11-05. The cloud coding session does not expose that tool. The generator's
backend model/version and a separate license grant were not exposed. **Do not
interpret this record as an MIT, Apache, CC0, or other third-party license
grant. Review the applicable generation/service terms before distribution.**
Existing repository and bundled-font licensing is unchanged.

### Rights investigation: 2026-11-06

This is an evidence record, not a license grant or legal clearance. No generated
illustration is marked CLEARED. The generation date recorded here is 2026-11-05;
the image IDs below and in `opening/ATTRIBUTION.txt` identify tool outputs, not a
provider, an accepted contract, a bundled-file checksum or proof of ownership.
No additional provider/license record was found in the existing provenance.

**Verified public policy evidence**

- Existing bundled notices identify Noto's SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`) and Roboto's Apache License 2.0
  (`assets/fonts/Roboto-LICENSE.txt`). They are unchanged and cover their font
  materials, not generated illustrations or a new application-code license.
- [GitHub Terms of Service, J.1/J.2/J.4/J.5](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service#j-ai-features-training-and-your-data):
  GitHub does not claim ownership of Input or Output. Output may be subject to
  third-party copyrights/licenses; users must determine required licenses and
  ensure lawful use. Non-ownership is not a third-party commercial license or
  a guarantee that generated output is copyrightable or non-infringing.
- The public policy repository's last path-specific revision before the recorded
  generation date is [166eb97e485b7de3cd5dbaf8c8d16e4310fda46c,
  committed 2026-04-27](https://github.com/github/site-policy/commit/166eb97e485b7de3cd5dbaf8c8d16e4310fda46c).
  Its [pinned Terms of Service](https://github.com/github/site-policy/blob/166eb97e485b7de3cd5dbaf8c8d16e4310fda46c/Policies/github-terms/github-terms-of-service.md)
  contain the same J.2 non-ownership and third-party-rights language.
  This proves dated public wording, not which agreement governed this image tool.
- The [live additional-product terms](https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features#github-copilot),
  displaying an effective date of 2026-08-27 when reviewed, route direct GitHub
  volume purchases to Generative AI Services Terms, Microsoft purchases to
  Microsoft Product Terms, and other Copilot users to Terms of Service J.
  The [pinned April product-terms snapshot](https://github.com/github/site-policy/blob/166eb97e485b7de3cd5dbaf8c8d16e4310fda46c/Policies/github-terms/github-terms-for-additional-products-and-features.md)
  still links Business/Enterprise to the older Copilot-specific terms.
  Do not silently treat that older routing as the November contract.
- [GitHub Generative AI Services Terms, March 2026](https://github.com/customer-terms/github-generative-ai-services-terms):
  section 2 says GitHub does not own Inputs or Outputs; 5 requires lawful use and
  compliance with resulting application licensing obligations. Section 1 limits
  applicability by purchase route. Section 7 routes optional pre-release features
  to pre-release terms. Section 8 distinguishes separately installed third-party
  products from third-party models directly incorporated by GitHub; provider
  terms must not be assumed merely because a model could be third-party.
- [GitHub Pre-release License Terms](https://docs.github.com/en/site-policy/github-terms/github-pre-release-license-terms):
  4(b) says GitHub does not own AI output; 2 limits use of the pre-release software
  to non-production evaluation/testing and notes separate component agreements.
  This is a candidate agreement, not proof this tool was governed by it. Its
  software-use limits must not be misrepresented as an explicit output-image
  commercial license or an established prohibition on every generated image.

**Unresolved facts / release blockers**

The tool's backend/provider/version, feature-specific terms, applicable account
purchase/preview agreement and accepted version at generation time are unknown.
There is no verified standalone commercial grant for these illustrations.
Third-party visual similarity, trademark/personality rights, AI copyright
eligibility and architectural authenticity are not cleared by the output IDs.
No claim is made that a particular provider's terms apply. A dated public policy
snapshot alone cannot settle these questions. Obtain written clarification from
GitHub/the supplying service, or an independently licensed replacement approved
by the user, before a commercial release or new parrot derivatives.

| Material | Verified fact | Release status |
| --- | --- | --- |
| All seven `home/` PNGs, including both parrots | Recorded original tool IDs and briefs | Generation/service and third-party rights pending |
| Nine `kids/` vocabulary PNGs | User-approved original generation, consistently padded on 2026-11-10 | Human art/rights review pending; see bundled notice |
| Both `opening/` WebPs | Source photograph's CC BY-SA 4.0 permission verified | Generated-adaptation rights and authenticity pending |
| New Phase C+ effects | Flutter code draws circles/rectangles and animates Material icons; no image/audio inputs | No new external asset license required; not an artwork-clearance claim |
| Audio | No recordings, music, voices or audio files added | Silent; future audio needs provenance and approval |

### Tirumala CC BY-SA compliance

The [Commons source page](https://commons.wikimedia.org/wiki/File:Tirumala_090615.jpg)
identifies Nikhil B/Wikimedia Commons (Nikhilb239), own work, and CC BY-SA 4.0.
Its permission explicitly includes commercial use and derivative works.
The [legal code](https://creativecommons.org/licenses/by-sa/4.0/legalcode.en)
2(a)(1) permits sharing/adaptation; 3(a) requires supplied creator/notices,
source/license links and modification notices; 3(b) requires a same-element
compatible adaptation license and forbids restrictions/DRM that impede reuse.
Other rights and endorsements are not granted (2(b), 2(a)(6)).

`opening/ATTRIBUTION.txt` supplies creator, source/license links, stylization and
technical modification notices, warranty notice, no-endorsement statement, and
CC BY-SA treatment of both adaptations, separately from app code. It is bundled
and registered in `LicenseRegistry` by `main.dart`. Welcome's credits action is
preserved; Settings now also opens licenses so returning users can access them.
These requirements have been documented and the notice wiring checked, but
generator rights remain unresolved: the two generated adaptations are not
commercial-release cleared. A later distributor must preserve these notices and
ensure its store/EULA/packaging does not restrict licensed artwork reuse.

No reference board or Meowdoku screenshots were attached or present in this
checkout. The artwork follows the user's written identity, not an assertion of
fidelity to unseen references. No Meowdoku cat, logo, source, or artwork was used.
The welcome parrot was used as the explicit visual reference for the celebration
pose and all four feature illustrations.
There is no lettering in the generated images; actual Telugu/English labels
remain Flutter text using the existing local fonts.

## Asset manifest and repeatable briefs

All paths below are under `assets/artwork/home/`. Keep rounded forms, soft
dimensional shading, gentle upper-left lighting, and blue/purple/teal/orange/
pink/gold accents consistent. Main palette: blue `#006EFF`, purple `#873AF2`,
teal `#00B894`, orange `#FF7A00`, pink `#FF406D`, gold `#FFD700`.

| File | Brief and role | Background |
| --- | --- | --- |
| `home-background.png` | Wide, welcoming Telugu-inspired mango orchard and lotus landscape, blue sky and layered soft hills; scenic Home panel, no characters or lettering | Opaque |
| `parrot-welcome.png` | Friendly original lime/teal parrot with yellow accents, orange beak, warm open expression and welcoming wing; entire silhouette inside frame | Transparent |
| `parrot-celebrate.png` | The **same** parrot, same proportions/colors/lighting, both wings lifted in a joyful pose; no trophies or score claims | Transparent |
| `classic.png` | Dimensional purple blank crossword board with rounded cream/gold tiles; no letters | Transparent |
| `learn.png` | Orange picture-learning cards with original mango/lotus pictures; no words | Transparent |
| `daily.png` | Teal rounded blank calendar with warm sun/gold accent; no numerals | Transparent |
| `progress.png` | Pink/purple garden-like steps leading to a gold star; not a claim of implemented tracking | Transparent |

Preserve genuine alpha, including transparent corners and antialiased edges;
a painted checkerboard is not transparency. Keep safe padding around the
complete illustration. Local lossless PNG optimization/resizing may be used
for bundled delivery; no runtime network fetches or new image dependencies.
The focused asset regression decodes all seven files with Flutter, checks
dimensions, byte budgets, and actual transparent/near-opaque pixel coverage.

Generated originals were 1774x887 RGB for the scene and 1254x1254 RGBA for
the cutouts. The coordinator used Pillow LANCZOS resizing, centered each cutout
inside a transparent canvas with a 32px safe border, and optimized PNG output.
The cloud integration then downsampled the delivered scene to 1280x640, parrots
to 512x512, and feature illustrations to 256x256 with Pillow LANCZOS and lossless
PNG encoding. The final seven files total 1,672,980 bytes. Flutter bounds decoded
image widths to 960/468/168 pixels for scene/mascot/feature art respectively.
Interior alpha is commonly 252-253 rather than exactly 255; tests require
substantial near-opaque coverage (alpha >=240), not artificially flattened art.

Original tool image IDs (SHA-256 identifiers, **not** bundled-file checksums):

| Asset | Original tool image ID |
| --- | --- |
| Background | `15d3f9eee78721819bbf60041354625fec1bb5f52eef729554e599f1172a414d` |
| Welcome | `63644640a47ff9faff239c38e240136828190e27df5952ad6b77a03b0bd52b40` |
| Celebration | `7725b129b5ae92bd3fb1294c7123a654c6e07a1c1201317b827683f4a2336f7c` |
| Classic | `92dae4b04ec9897f399b66463366eaddd12b02b62c165dda3a79e49204f85002` |
| Learn | `454f38cd2e2d3be07b4e6ab309e64f6db84c6eec80c29b08ad8dd8aa238ad37d` |
| Daily | `4a4241fdf7de47df26c88a8e11c34d06a3b34e40d0b5ba30f2360e0608343337` |
| Progress | `954c44debb7306cb358f2527198c1eeae3f56392b698fa80a45151bc19b554ba` |

## Integration and motion

### Bal Hanuman special achievement: original Flutter vector character

The supplied Meowdoku screenshot and Bing search-result thumbnails are visual
references, not licenses or an original character master. No original Bal
Hanuman artwork, layered rig, source license or verified sound was found in
the bundled assets. No search-result images, modern cartoon designs, voices,
music or animation packs were copied, traced, downloaded or bundled.

On 2026-11-07 the user approved "Create an original Flutter-drawn Bal Hanuman
(Recommended)" after being told this would be stylized vector art rather than
a fully rendered illustration. `lib/widgets/bal_hanuman_character.dart` is the
editable master: original Canvas paths, ovals, strokes and gradients authored
in this repository with GitHub Copilot. No image-generation service, downloaded
artwork, traced reference or third-party animation rig supplies its geometry.
Its design uses traditional mythological attributes: a friendly monkey face,
orange dhoti, gold ornaments, small gada and curled tail. It does not reuse
the parrot or a modern cartoon's character, costume, logo, voice or pose.

Head, arm, wrist, tail and gada have separate canvas pivots; eye shapes briefly
blink. These are actual independent 2D vector transformations, not a single
moving bitmap or a claim of 3D/full skeletal animation. The existing 3.5-second
timeline owns all motion, skip, reduced-motion and lifecycle handling.
`lib/widgets/special_achievement_celebration.dart` supplies finite light/particle
effects and three decorative stars, not extra rewards. Actual star totals and
Telugu word tiles remain unchanged. The parrot stays the everyday mascot.

This records provenance and local-development approval, not legal clearance.
No top-level LICENSE file was found during this change. Commercial distribution
of repository source, any applicable accepted Copilot terms and third-party
rights still require the release owner's review; no license grant or CLEARED
status is invented. Existing disputed generated assets retain their prior status.
No image/audio asset, layered export or pubspec dependency was added.

An optional external illustration slot still moves only the whole supplied
widget. Independently animated external artwork would require licensed layers.

Optional replacement artwork, after rights review and approval:

- `assets/artwork/celebrations/bal_hanuman/character.webp`: original transparent
  full-body illustration, suggested 768x1024, target <=400 KiB; friendly joyful
  face, orange dhoti, gold ornaments, small gada and curled tail. No text baked
  in. Retain the editable source outside the production asset bundle.
- `assets/artwork/celebrations/bal_hanuman/provenance.json`: creator, creation
  date, source/master ID, applicable agreement/license and version, documented
  commercial distribution/modification permissions, third-party-rights review,
  approval record and any remaining questions. Unknown rights stay pending.
- For later articulation: separately exported `body.webp`, `head.webp`,
  `raised-hand.webp`, `gada.webp`, `tail.webp` and `rig.json` describing common
  canvas coordinates, pivots, layer order and safe rotation limits. Obtain the
  editable layered source and licensed modification rights before preparing
  these derivatives. This task creates none of these files.
- Optional reviewed audio: `assets/audio/celebrations/magic-entrance.wav`,
  `star-reward.wav`, `level-completion.wav`, with corresponding provenance and
  commercial/derivative permission records. No audio is currently bundled;
  existing sound preferences/lifecycle gates retain intentional silence.

Commission an independently designed, respectful mythological interpretation;
approval of a concept alone does not clear modern third-party character art.
No generated-output ownership statement is treated as a commercial license.
No asset is marked CLEARED here. Before adding files, verify the actual source
terms, record evidence/attribution and obtain approval; then register the approved
asset directory in pubspec and bound the image's decode size for target devices.

Phase C+ adds code-only correct-answer star pulses (420ms), encouraging retry
feedback (220ms), 16 deterministic circle/rectangle completion particles (900ms),
and 2.5% Material-button press feedback (100ms down / 140ms release). These use
Flutter animation, Canvas and existing Material icons; no new asset files,
reference images, sound, GIF, Lottie or character derivatives were used.
New motion stops when hidden, covered, backgrounded or reduced motion is enabled,
and does not resume stale celebrations. Scoring/reward ownership stays in the
learning controller; only an actually earned star receives new-reward wording.
The reusable reaction widget accepts a decorative child, but no parrot image is
attached to it. Existing parrot images and their existing Home motion are unchanged.
Audio is a silent backend with an OFF-by-default session preference; future
backends require reviewed bundled sources and must cancel pending/active playback.
No event queues audio for later replay after navigation, resume or re-enabling.

The richer Kids completion scene in `lib/widgets/kids_completion_scene.dart`
is newly authored Flutter/Canvas geometry: an eight-petal blue achievement
medallion, a shaded five-point gold star, 16 bounded particles and a curved
new-reward flight. It uses existing theme colors, Material icons and licensed
fonts, not Meowdoku images, poses, branding or animation files. The 800ms scene
replaces the static completion illustration on both Kids completion surfaces;
the parrot files and its presentation elsewhere remain unchanged. The actual
session-star count and final learned word remain visible without waiting for
motion. Replay does not fly/claim another earned star, and original practice
does not claim a learning reward. No new image/audio assets or external providers
are involved; this does not change pending clearance of existing generated art.

On compact screens, the title and tagline sit over the decorative scene with a
blue contrast scrim; other body text and actions remain outside the artwork.
The header grows with text, and the parrot stays on the right. Wider screens
retain the side-by-side composition. The parrot welcomes new sessions and uses
its static celebration pose when returning to Home after
visiting Classic (a welcome-back illustration, **not** a completion reward).
Feature illustrations retain real labels, Coming Soon states, and existing
keyboard/semantic activation. Decorative images are excluded from semantics.
Large accessibility text hides the optional Home scene to prioritize content;
cards keep their illustration and expand/scroll instead of clipping labels.

Existing Flutter entrance/press motion is retained. The static parrot has only
a gentle three-pixel bob; this is **not expressive character animation**.
Its idle timer and animation stop on other tabs, under Settings, while the app
is backgrounded, and with system reduced motion. No Rive/Lottie dependencies
or new gameplay are introduced.
