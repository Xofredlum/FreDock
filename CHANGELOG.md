# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog
and this project follows Semantic Versioning.

---

## [1.4.0 RC1] - 2026-07-08

### Added

- Theme Manager with **Dark**, **Light** and **System** modes.
- Window transparency support.
- New `DESIGN.md` documenting FreDock design philosophy.
- Improved modular architecture.

### Changed

- Simplified window title (`FreDock`).
- Improved interface consistency and spacing.
- Refined Visual Button Editor.
- Enhanced Settings dialog.
- Updated splash screen.
- Improved hover effects and premium micro-interactions.
- Refined bottom toolbar interactions.
- Improved overall UI polish.
- Updated documentation.

### Fixed

- Various visual alignment issues.
- Theme switching stability improvements.
- Settings persistence improvements.
- Minor UI and usability fixes.

---

## [1.3.0] - 2026-07-07

### Added

- Visual Button Editor
- WYSIWYG button editing directly from the main interface
- Edit mode with clear visual feedback
- `✔ Done` button to leave edit mode
- `➕ Add` button to create new clipboard buttons
- Button editor dialog with name and text fields
- Delete option for existing buttons
- Automatic button renumbering after deletion
- Character counter in the editor window
- Improved edit mode title and status feedback

### Changed

- FreDock is now presented as a lightweight visual clipboard launcher
- Improved button editing workflow
- Improved edit mode ergonomics
- Improved editor window layout
- Improved Add button visibility
- Improved status messages
- Safer INI saving using a temporary file workflow
- Better synchronization between the INI file and the interface
- Updated About and version information for 1.3.0

### Fixed

- Fixed unreadable text in edit fields on dark interface
- Fixed delete confirmation appearing behind other windows
- Fixed possible INI reload conflict while saving buttons
- Fixed potential button list corruption during add/delete operations
- Fixed destroyed control error caused by delayed status timers
- Improved stability when switching between normal mode and edit mode

## [1.2.0] - 2026-07-06

### Added

- Initial public release
- Unlimited configurable buttons
- Portable executable
- Automatic INI reload
- Dark user interface
- Splash screen
- Settings dialog
- Always-on-top mode
- Snap positions
- Window position memory
- About dialog
- Help dialog

### Changed

- Compact interface
- Improved button layout
- Refined visual design
