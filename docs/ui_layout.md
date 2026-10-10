# UI layout foundation

The reference viewport remains 720 x 1280 with `canvas_items` and `expand`.
Production typography and the existing theme remain unchanged.
This foundation is opt-in; no production scene is migrated yet.

## Native hierarchy

```text
Screen (Control, full rect)
  Background (full rect, outside safe margins)
  SafeContent (MarginContainer + safe_area_margin.gd, full rect)
    Layout (VBoxContainer)
      Header (HBoxContainer, content-sized)
      Content (Control/container, expand fill vertically)
      Footer (HBoxContainer, content-sized)
```

For long content, use a native `ScrollContainer` in the Content slot with an
expand-fill inner container. Keep Back/Close actions reachable in Header/Footer.
Use a `CenterContainer` inside Content for short modal/card compositions, and
preserve illustration proportions. Do not scale the whole screen to fill space.

## SafeAreaMargin API

- Attach the script to a screen-aligned `MarginContainer` in screen-space UI.
- `content_padding`: left/top/right/bottom spacing in local UI units; defaults
  to zero and clamps negative values. Set explicit authored spacing here rather
  than also setting the four margin theme overrides owned by this helper.
- `refresh_safe_area()`: explicit refresh after a platform UI transition if needed.
- `safe_insets()`: applied platform-only margins, excluding content padding.
- `calculate_insets(safe_rect, local_to_display, local_size)`: pure conversion
  used by focused tests; inputs are display pixels and the complete screen transform.

On Android/iOS the platform safe rectangle is converted with the inverse of
`get_screen_transform()`. This already includes window placement, canvas transforms
and stretch: do not divide by stretch, DPI or device pixel ratio a second time.
The resulting bounds are clamped to this container before outward integer rounding.
System-excluded space and safe ancestors therefore add no duplicate insets.
Desktop/headless defaults to zero platform margins instead of using the desktop
work area as a mobile notch. Authored padding is applied once on top.

Refresh is deferred/coalesced on ready, container/viewport resize, transform change,
application focus and resume. Orientation changes re-read current dimensions and
platform bounds; no portrait-specific offsets are cached. No per-frame polling,
autoload, input handler or theme replacement is introduced.

Do not rotate/skew or mirror the safe root; animate its content instead. Positive
axis-aligned scales and translations are supported. Unavailable/empty platform
bounds, zero size or unsupported transforms yield zero platform margins.
Use the platform safe rectangle conservatively; native ad/UMP forms stay SDK-owned.
Physical Android/iOS verification is still required when production scenes adopt it.

## Gameplay boundary

Keep Arena, Player, Enemy, Ghost, Camera2D and world-space effects outside SafeContent.
Do not change PLAY_RECT, grid sizing, camera, physics or input coordinates.
Backgrounds/dimming remain full-screen; the helper itself ignores pointer input.
Existing child controls retain their own mouse/input behavior.
Moving a D-pad requires separate approval and a shared visual/input-center change.
