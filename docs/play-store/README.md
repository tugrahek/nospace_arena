# Google Play asset review package — R3

Final asset integration pass, based on `main@eb95d26`, 26 October 2026.
Existing branding and EN/TR feature graphics are accepted for this pass and unchanged.
Both Android profiles now use the approved launcher layers. No Play Console upload
is implied. Gameplay, frozen Settings and monetization are unchanged.

## Review assets

| Asset | File / dimensions | Status |
|---|---|---|
| Play icon | [512×512 PNG](icon/play-icon-512.png) | Accepted identity; technical PASS |
| Android legacy launcher | [192×192](android-launcher/launcher-192.png) | Applied to development APK and unsigned AAB |
| Adaptive foreground | [432×432 RGBA](android-launcher/adaptive-foreground-432.png) | Transparent layer; safe-zone PASS |
| Adaptive background | [432×432 RGB](android-launcher/adaptive-background-432.png) | Full opaque void color |
| Themed monochrome | [432×432 RGBA](android-launcher/adaptive-monochrome-432.png) | White alpha silhouette; safe-zone PASS |
| Mask review | [Circle/square preview](android-launcher/mask-preview.review.png) | Review only; not a Play upload asset |
| Feature graphic EN | [1024×500 RGB](feature/feature-en-1024x500.draft.png) | Accepted; original filename retained |
| Feature graphic TR | [1024×500 RGB](feature/feature-tr-1024x500.draft.png) | Accepted; original filename retained |
| Screenshots EN, upload order | [Capture 02](screenshots/gameplay-en-02.png), [drawing 01](screenshots/gameplay-en-01.png), [Mode Select](screenshots/mode-select-en.png) | 3 native 1080×1920 RGB PNGs |
| Screenshots TR, upload order | [Capture 02](screenshots/gameplay-tr-02.png), [drawing 01](screenshots/gameplay-tr-01.png), [Mode Select](screenshots/mode-select-tr.png) | 3 native 1080×1920 RGB PNGs |
| Listing text | [EN/TR JSON](listing.json) | Draft; language/publisher approval required |
| Technical results | [Validation / image hashes](validation.json) | Automated checks only |

## Identity and sources

`assets/icon.svg` is the older cyan **N** placeholder. `docs/media/logo.png` is
the existing 1024×1024 README/game-brand mark, with the arena, claimed areas and
player diamond. The package follows that existing mark; the SVG, original PNG and
its existing `.import` file are untouched. The Play icon is a 50% downsample into
a full-square opaque background with an explicit sRGB chunk and 32-bit RGBA PNG.
No outer corner mask, shadow, rank/price badge or new gameplay artwork was added.

Adaptive layers derive from the same mark. The source void color is keyed out of
the foreground and supplied as the opaque background. The 108 dp layers use 4 pixels
per dp (432×432). Every visible foreground/monochrome pixel fits inside the central
66 dp diameter circle. The existing logo geometry/colors remain recognizable under
circle and square masks; physical launcher/OEM/themed appearance still needs review.
Feature graphics contain only the existing logo and typography, with EN/TR copy;
they do not depict or invent a gameplay scene. The wordmark uses the existing
DynaPuff font; other graphic text uses the Windows Segoe UI renderer. Font binaries
are not copied into this package; DynaPuff attribution remains in [credits](../credits.md).

## Screenshot provenance

The old `docs/media/gameplay.png` is a 720×1280 image and the GIF is only 360×640.
Neither was enlarged for this package. Existing UI acceptance images can use
in-memory score/currency fixtures, so they were not selected as store screenshots.

`tools/capture_store_gameplay.gd` instantiates the actual Game scene in normal Free
mode, uses default loadout/save values and sends keyboard direction events. It
does not set grid cells, score, lives, enemy positions, RNG, rewards or game status.
Two independent normal runs provide EN/TR captures. The observed 37,848 score and
territory effect come from an actual completed cut. [Capture provenance](screenshots/capture-provenance.json)
records the real score/lives/state, locale, framebuffer dimensions and renderer.

The four original gameplay 01/02 captures remain unchanged. The repetitive 03
frames are replaced by actual `ModeSelect.tscn` renders in both languages, showing
Daily, Free, Endless and Campaign with the default isolated save (no unlock,
currency or progress fixtures). [Upload order](screenshots/order.json) is 02, 01,
Mode Select for each locale. The Mode Select screen is not a campaign-progress claim.

These are **Windows Godot OpenGL renders**, not Android phone captures. The
SubViewport framebuffer is natively 1080×1920, with the game's normal 720×1280
logical canvas; vector/UI content is rendered at that framebuffer resolution.
No saved 720p bitmap was enlarged, no HUD was retouched, and no device frame or
marketing overlay was added. Native desktop resolution is not Android device
acceptance; confirm matching appearance on a later signed device build.

## Reproduce and validate

On Windows, run `tools/prepare_play_store_assets.ps1` to regenerate brand derivatives
using built-in System.Drawing. It does not touch gameplay captures. The script uses
explicit Unicode for Turkish text so PowerShell 5.1 source encoding cannot corrupt it.

For fresh gameplay captures, use the matching Godot 4.6.3 executable with a real
`gl_compatibility` renderer and `-s res://tools/capture_store_gameplay.gd`, with
**APPDATA pointed to a dedicated temporary directory**. No real player profile
should be used. Gameplay evolves normally, so enemy positions/timing may differ.
This is a render capture command, not a headless test.
Append `-- --modes-only` to preserve existing gameplay 01/02 captures and their
provenance while replacing only the two Mode Select renders.

Run `python tools/validate_play_store_assets.py --report docs/play-store/validation.json`.
It checks PNG CRCs/decoding, dimensions, bit depth/channels, opacity/transparency,
icon size and adaptive safe-zone geometry, plus EN/TR text limits and capture metadata.
The package's `.gdignore` and R1 `docs/*` release exclusion keep review art out of
game exports. Four byte-identical runtime copies live in `assets/branding/launcher/`.

Both Android profiles map these imported runtime copies to Godot's
`launcher_icons/main_192x192`, `adaptive_foreground_432x432`,
`adaptive_background_432x432` and `adaptive_monochrome_432x432` settings. Those
settings. APK format/debug signing and release AAB format/unsigned signing,
package identity, SDK settings and test-ad defaults are preserved. Validation
checks the four source/copy identities and both profiles' mappings.

The isolated R1 workflow also produced both exports successfully (import/APK/AAB
exit 0). [Artifact evidence](android-export-validation.json) records hashes,
package/SDK values, unsigned AAB status, native ELF load alignment, 16 KB bundle
configuration, APK signature/zip alignment and 24 packaged launcher WebPs matching
generated resources in each artifact. Source development AGP remains 8.6.1; the
isolated R1 workspace uses its verified 8.9.1 override. This is artifact evidence,
not physical-device or Play Console acceptance. Local logs remain under the
ignored `export/r3-final-verified/` directory; shutdown ObjectDB warnings are noted.

## Listing accuracy and alt text

The text describes capture/trail risk, actual territory effects, unlocks, four
modes, 12 campaign stages, missions/login rewards, three controls and 18 languages.
Daily best scores are explicitly local. It promises no online ranking,
cloud account, roguelite draft, ad-free experience or current production purchase.
Sources: [project README](../../README.md), `resources/`, `scripts/core/game.gd`,
`scripts/autoload/SeedManager.gd` and the current EN/TR translation catalog.

Suggested upload alt text (all below 140 characters):

| Asset | EN | TR |
|---|---|---|
| Feature | NoSpace Arena logo and the words Draw a line. Take the void. | NoSpace Arena logosu ve Çizgiyi kapat. Alanı ele geçir. yazısı |
| Gameplay 01 | The player draws a cyan trail into the dark arena while avoiding an enemy. | Oyuncu, düşmandan kaçınırken karanlık arenaya camgöbeği çizgi çekiyor. |
| Gameplay 02 | A completed cut fills the captured area and displays the earned score. | Kapanan çizgiyle bölge doluyor ve kazanılan skor görünüyor. |
| Mode Select | Daily, Free, Endless and Campaign modes on the game's mode selection screen. | Oyunun mod seçimi ekranında Günlük, Serbest, Sonsuz ve Macera seçenekleri. |

## Approval before upload

1. On a signed physical Android build, inspect the launcher at small sizes, under
   round/squircle masks and Android themed icons; the approved mark must remain legible.
2. Open Mode Select in EN/TR and compare to these renders; cards/text must match,
   with no clipping. Compare real gameplay to captures 02/01 and check touch controls.
3. Review the TR listing and local-only Daily score description before
   publishing. Branding/feature acceptance does not imply Console or device acceptance.

Requirements checked against [Play preview assets](https://support.google.com/googleplay/android-developer/answer/9866151),
[Play icon specification](https://developer.android.com/distribute/google-play/resources/icon-design-specifications),
[Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive),
and [listing limits](https://support.google.com/googleplay/android-developer/answer/9859152).
Icon: 512² / RGBA / sRGB / at most 1024 KB. Feature: 1024×500 / RGB, no alpha.
Screenshots: RGB PNG, portrait ratio within 2:1; three 1080×1920 captures per locale.
Listing limits: title 30, short description 80, full description 4,000 characters.
