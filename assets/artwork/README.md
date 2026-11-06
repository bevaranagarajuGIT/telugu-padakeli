# Home artwork

## Phase C educational crop

`kids/mango.png` is an 88x126 lossless crop of the approved original
`home/learn.png`, using Pillow's `(70, 74, 158, 200)` pixel rectangle. It isolates
the mango illustration for picture matching instead of asking a child to identify
one object from a mixed mango/lotus scene. The approved source PNG is unchanged.
The other playable picture is the existing `home/parrot-welcome.png`.
Both are bundled offline with Telugu image descriptions; neither is a new
third-party download or a placeholder. The source artwork's generation/service
terms and distribution-review limits below also apply to this derived crop.
More fruits, animals and everyday objects require original or licensed,
human-reviewed illustrations before expanding the picture activity.

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
