# FreDock Design Notes

FreDock is designed as a small, focused Windows utility.

It should feel lightweight, immediate and pleasant without becoming visually noisy.

## Core principles

- If in doubt, keep it simple.
- Minimal is premium.
- Every interaction should feel effortless.
- The interface should breathe.
- Micro-interactions should be felt more than noticed.
- Do not add a setting unless it solves a real user need.
- If an information already exists clearly somewhere else, do not repeat it.

## Window title

The main window title is always:

```text
FreDock
```

Version information belongs in About, Splash, GitHub releases and executable metadata.

## Appearance

FreDock supports:

- Dark
- Light
- System

No custom color palette is provided. The goal is coherence, not clutter.

## Transparency

Transparency is limited to a safe range from 70% to 100% to preserve readability.

## Future note

Auto Paste is intentionally deferred to 1.4.5 because it changes workflow behavior and does not belong to the 1.4 polish scope.
