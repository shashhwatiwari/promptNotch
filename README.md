# DynamicNotch

DynamicNotch is a lightweight macOS teleprompter that places speaking notes near the MacBook camera/notch area so users can keep natural eye contact during calls, recordings, interviews, and presentations.

## Current Build

This first version focuses on the core workflow:

- Write or paste scripts in the main editor.
- Import `.txt` and `.md` files.
- Show or hide a floating always-on-top prompt overlay.
- Control the app from a discreet menu-bar extra.
- Start, pause, and reset automatic script scrolling.
- Pause automatically while hovering over the prompt.
- Use hover controls for close, minimize, play/pause, scroll-back, and Settings.
- Reopen the same Settings window repeatedly without creating duplicates.
- Edit settings against a built-in preview, then apply changes to the live overlay.
- Control reading pace with words per minute.
- Auto-size the prompt by visible line count, or resize it manually.
- Move the prompt to camera, top-center, left, right, or a custom dragged position.
- Adjust font size, line spacing, opacity, theme, and text weight.
- Use a notch-attached glass surface, top/bottom fades, dimmed bracket cues, and a slim progress rail.
- Enable click-through mode for meetings and recordings.
- Switch between Minimal, Standard, and Presenter modes.
- Keep prompt preferences saved between launches.

## Run

```sh
swift run DynamicNotch
```

## Build

```sh
swift build
```
