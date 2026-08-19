# Countora branding

Countora's repository-owned editable mark lives at:

- [`../assets/branding/countora-mark.svg`](../assets/branding/countora-mark.svg)

## Concept

The mark combines:

- a rounded product tile for cross-platform app-icon use;
- a circular timer dial;
- three separated progress arcs representing simultaneous timers/interval phases;
- a clear central countdown hand;
- a compact top timer control silhouette.

The source is plain SVG so it remains editable without proprietary design software.

## Brand principles

- Simple enough to remain recognizable at launcher-icon sizes.
- High-contrast geometry that works on dark and light presentation surfaces.
- No third-party trademark or stock-art dependency.
- No text baked into the mark, so localization does not affect the icon.
- Visual language matches Countora's Material 3 seed color family without requiring exact UI-theme colors.

## Source of truth

Do not hand-edit generated PNG/ICO/ICNS launcher exports and treat them as primary source. Edit the SVG, review it, then regenerate platform-specific icon outputs in the release/design environment.

## Platform export checklist

Before a stable release:

1. export lossless square source renders at sufficiently high resolution;
2. generate Android adaptive/legacy launcher assets;
3. generate iOS AppIcon assets without transparency where Apple guidelines require it;
4. generate macOS app-icon assets;
5. generate Windows icon resources;
6. generate Linux desktop icon sizes;
7. generate Web favicon/PWA icons;
8. verify safe-area/corner masking on each target;
9. verify no source export introduces a watermark or third-party asset;
10. commit generated release assets only when their generation path is reproducible.

## Splash/launch treatment

Use the Countora mark centered on the platform-default launch background with minimal motion. Do not create fake loading delays. The application performs local initialization before presenting the main timer UI, so any native launch treatment should exist only for genuine startup work.

## Screenshots

Only commit screenshots captured from a real runnable Countora build. Do not substitute design mockups for product screenshots.

## Credit

The product's visible project credit remains:

**Made by the Sanskar**
