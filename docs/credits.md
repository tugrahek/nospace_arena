# Credits / Künye — NoSpace: Arena

© 2026 Tuğra Hekimoğlu — all rights reserved (proprietary).

## Engine & Tools
- Godot Engine 4.6 (MIT)
- GUT — Godot Unit Test (MIT)
- Poing Studios Godot AdMob Plugin 5.1.0 (MIT): https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0
- GodotGooglePlayBilling 3.3.0 (MIT): https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0

## Assets
Third-party font licenses and attribution are listed below. Runtime font notices are
also available in Settings → Open-source licenses; addon editor font notices are
included alongside their vendored files.

| Asset | Type | Author | License | Source |
|-------|------|--------|---------|--------|
| DynaPuff | Font (NoSpace brand wordmark only) | Toshi Omagari, Jennifer Daniel | OFL 1.1 | Google Fonts |
| Rubik | Font (screen / section headings) | Hubert and Fischer, Meir Sadan, Cyreal, Daniel Grumer, Omaima Dajani | OFL 1.1 | Google Fonts |
| Nunito Sans | Font (body / button / numbers) | Vernon Adams, Jacques Le Bailly, Manvel Shmavonyan, Alexei Vanyashin | OFL 1.1 | Google Fonts |
| Noto Sans CJK SC Regular 2.004 (subset) | Font (vendored AdMob editor interface) | Adobe; Noto is a Google trademark | OFL 1.1 | [Original OFL](../addons/admob/assets/fonts/OFL.txt) · [Copyright and verified provenance](../addons/admob/assets/fonts/NOTICE.txt) |
| NoSpace CJK JP/KR/SC/TC Subset | Font (regional gameplay/UI fallback; derived from Noto Sans CJK 2.004) | Adobe; Noto is a Google trademark | OFL 1.1 | [Source, hashes and subset details](../assets/fonts/cjk/NOTICE.txt) · [OFL](../assets/fonts/cjk/OFL.txt) |
| SFX (capture / ui_tap / life_loss / near_miss) | Audio | Tuğra Hekimoğlu | original / synthesized | — (no third-party asset) |
| Menu music (menu_music) | Audio | Tuğra Hekimoğlu | original / synthesized | — (no third-party asset) |

> NOT: Production font dosyaları ve aile başına OFL.txt metni `assets/fonts/` altında tutulur.
> `ui_theme.tres`, body, button ve numbers için Nunito Sans; screen/section headings için Rubik
> bağlar. DynaPuff yalnız MainMenu `NoSpace` wordmark override'ıdır.

Asset policy: all fonts/audio/sprites must be license-clean (CC0 or commercial-use);
reference games are inspiration only — no copied assets/IP.

## Runtime legal notices
The Poing plugin MIT notice is embedded in `config/legal_notices.tres` and shown in
Settings licenses when the plugin is bundled. The original addon license remains intact.
The GodotGooglePlayBilling MIT notice is embedded in the same resource and included
when its GDScript client is bundled; its original addon license remains intact.
The legal reader sources the Godot Engine MIT text and engine third-party notices from
`Engine.get_license_text()`, `Engine.get_copyright_info()` and `Engine.get_license_info()`.
Exact bundled font OFL texts are embedded in `config/legal_notices.tres` so exports retain
these notices even when plain text files are not included. Original OFL files remain intact.
GUT is a development dependency. Its MIT and bundled font notices appear only if GUT code
is present in the running package. The current local all-resources export preset has no
exclusions and therefore includes GUT; a production preset excluding the development addon
and tests will automatically omit its legal notice from the reader.

CJK runtime fallback fonts retain region-specific outlines and OpenType layout. They cover
the shipped catalog and language endonyms, not arbitrary CJK text. Regenerate all four
subsets when adding characters; catalog glyph coverage is checked by focused localization tests.
