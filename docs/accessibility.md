# Accessibility

Countora is designed so timing status does not depend on sound, vibration, color, or precise pointer input.

## Implemented baseline

### Semantics and assistive technology

- Timer cards expose the timer identity, remaining time, and status through semantics.
- Activating a timer card is announced as **Open focus mode**; the full-screen close control separately announces **Exit focus mode**.
- Progress indicators expose semantic labels/values rather than relying only on a visual bar.
- Full-screen focus mode exposes a live countdown semantic region.
- Icon-only controls include tooltips that also improve discoverability.
- Destructive operations use descriptive confirmation dialogs.

### Non-audio cues

Sound and vibration are optional. Countdown state remains visible through:

- large remaining-time text
- progress bars
- running/paused/completed status controls
- interval-step labels and ordering
- focus-mode visual countdown
- system visual notifications where the target supports scheduled notifications and quiet mode suppresses sound/vibration

Web and Linux currently rely on the in-app timer state/cues for future completion because Countora's notification adapter does not schedule future background notifications on those targets.

The Settings Accessibility section explicitly describes these non-audio cues.

### Keyboard and desktop access

Standard Flutter focus traversal applies to interactive controls. Additional shortcuts:

- `Ctrl/Cmd + N` — create timer/preset
- `Ctrl/Cmd + F` — focus timer search
- `Ctrl/Cmd + ,` — open Settings

The same primary actions remain reachable without shortcuts.

### Motion

The Reduced motion setting propagates through `MediaQuery.disableAnimations`, preserving any platform-provided reduced-motion preference as well.

### Text and layout

- UI uses Flutter text themes rather than fixed bitmap text.
- Main views are responsive across phone/desktop widths.
- Timer cards can switch to compact density without removing core controls.
- Scrolling is available for long Settings, dialogs, and history/preset lists.
- Primary button theme touch targets are at least 48 logical pixels high.

## Color and status

Do not encode timer state only with color. Running/paused/completed states have text/icons/actions in addition to theme colors.

Theme colors are derived from a Material 3 color scheme. Contrast must still be manually checked for any future custom color outside the scheme.

## Testing

Automated regression coverage includes timer semantic labels, the focus-mode entry hint, progress semantics, and key Settings/keyboard journeys. Localization tests also protect the distinct open/exit focus-mode copy.

Automated tests are not a substitute for a manual accessibility pass.

Before a stable release, manually verify:

- TalkBack on Android
- VoiceOver on iOS/macOS where available
- Windows Narrator where available
- keyboard-only navigation on desktop/web
- 200% or larger text scaling
- light/dark theme contrast
- reduced-motion behavior
- quiet mode with all audio/haptics disabled
- focus visibility and modal focus trapping
- focus-mode card/action announcements with a real screen reader

## Contributor checklist

For every new interactive feature:

1. Give icon-only controls a tooltip/semantic purpose.
2. Ensure action hints describe what activation will do next, not the inverse action available after navigation.
3. Ensure it is keyboard reachable on desktop/web.
4. Do not rely only on color/sound/vibration.
5. Confirm scaled text does not remove the action.
6. Respect reduced motion.
7. Keep destructive actions explicit and reversible where practical.
8. Add regression semantics/widget coverage when the behavior is important.
