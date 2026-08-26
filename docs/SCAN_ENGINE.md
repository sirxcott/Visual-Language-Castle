# Visual Language Castle — Scan Engine

The Scan Engine is a core product system, not a convenience feature.

## Goal
Maximize rapid visual scanning and minimize interruption between seeing a useful linguistic component and placing it into the active workspace.

The user should be able to keep the right hand on the mouse while the left hand changes visible tables and navigation state.

## Primary Interaction Loop
**SEE → SCAN → SELECT → PLACE → CONTINUE SCANNING**

## Scan Mode
When enabled:
- minimize interface chrome
- maximize card density
- maximize simultaneous table visibility
- suppress unnecessary animations
- keep active workspace available
- preload/cached nearby tables

## Table Rail
Provide a visual rail of table thumbnails. Recognition should be visual, not dependent on reading table names.

Possible positions:
- bottom horizontal rail
- side vertical rail
- configurable dock

Hover or keyboard focus temporarily enlarges/previews a table.

## Rapid Table Cycling
Support remappable commands conceptually similar to:
- Q / E — previous / next table
- 1–9 — favorite tables
- Shift + 1–9 — second favorite bank
- Tab — journal/table browser
- F — favorite/pin
- Z — room overview
- N — create note
- Ctrl/Cmd + Z — undo
- Shift + drag — multi-select
- Alt/Option + drag — duplicate

Exact bindings are provisional.

## Pinned vs Floating Tables
Pinned tables remain in the workspace.

Floating/temporary table slot:
- appears for rapid scanning
- can cycle independently
- taking a card does not remove pinned tables

Example: four pinned tables remain visible while Q/E cycles a fifth temporary table.

## Palette Sets
Users can save groups of commonly used tables and load them instantly.

Examples:
- Relaxation / Beginning Set
- Resource Set
- Exploration Set

## Room Overview
One keypress should zoom out to reveal all currently mounted tables. A second press returns to the active work area.

## Rapid Extraction
Support more than long-distance dragging:
- drag — direct placement
- double-click — send to active construction row
- shift-click — send to temporary tray
- keyboard selection — advanced rapid extraction

## Table Browser / Carousel
Provide a fast visual browser showing many table thumbnails at once. Avoid conventional nested menu navigation.

## Recent History
Maintain quick visual access to recently used tables, e.g. last 5.

## Search
Search must be usable during active scanning and should show source table/category immediately.

## Performance Requirement
Active, pinned, favorite, recent, and neighboring tables should be cached/preloaded so table switching feels effectively instantaneous.

## Success Criterion
A skilled user should be able to switch tables, scan, extract a card, and continue constructing without perceptible disruption to visual momentum.
