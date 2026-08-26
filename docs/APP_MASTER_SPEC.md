# Visual Language Castle — Master Specification

## Purpose
Visual Language Castle is a desktop-first visual language construction, study, and research environment based on a physical system of handwritten, color-coded sticky-note tables.

The app combines a castle/memory-palace interface with rapid visual scanning, movable linguistic cards, reusable language frames, research rooms, saved constructions, annotations, and a portable journal.

## Primary Design Principle
The system exists to reduce the limitation of notebook pages hiding information from view. The digital version must maximize simultaneous visibility and minimize the delay between seeing a useful component and placing it into the active workspace.

Primary interaction loop:

**SEE → SCAN → SELECT → PLACE → CONTINUE SCANNING**

Avoid menu-heavy workflows during active construction.

## Castle / Memory Palace
The castle is the organizational metaphor, not a barrier to speed.

Initial environments:
- Grand Gallery — hub with paintings/portals to rooms.
- Archive — original tables displayed on walls for browsing and practice.
- Research Laboratory — active experimentation with multiple tables, cards, notes, and connections.
- Completed Works Gallery — finished boards and saved work.
- Sentence / Construction Vault — reusable saved constructions.
- Personal Rooms — user-created project spaces.
- Scriptorium — print/export destination, also accessible by shortcut.

The castle may use 2.5D scenes, parallax, animated doors, and illustrated rooms rather than a full 3D game engine in the first release.

## Research Journal / Alchemy Book
Persistent portable interface with sections for:
- Tables
- Favorites
- Palette Sets
- Cards
- Saved Constructions
- Notes
- Recent
- Search
- Rooms

Users can favorite an entire table in the Archive and later drag it from the journal into another room.

## Tables as Objects
A whole table can be placed, resized, pinned, moved, favorited, duplicated, removed from a room, and used as a source for extracting individual cards.

Each table can support:
- Original View
- Scan View
- Category View
- Search View
- Favorites View

Original spatial arrangement must remain preserved as source metadata.

## Construction Board
Support:
- free placement
- soft snap
- row snap
- automatic horizontal reordering
- multiple rows
- groups
- duplication
- deletion
- locking
- zoom/pan
- undo/redo
- subtle rotation
- wall/chalkboard/corkboard/whiteboard/stone/wood/custom backgrounds

## Read-Across Mode
Provide a distraction-reduced mode for reading selected sequences left to right.

Do not automatically rewrite sequences into polished prose. The human user supplies connective language and improvisation.

## Slot Frames
Some cards contain functional insertion slots.

Example:
`THE MORE [____], THE MORE [____]`

Inserted cards remain individually editable.

## Wall Annotation
Logical layers:
1. Environment layer
2. Object layer
3. Annotation layer

Support freehand marks, arrows, circles, connectors, labels, and notes attached to connections.

## Card Notes
Every sticky note can hold user-created notes separate from source text. Hover may reveal note/favorite indicators; click opens an inspector.

## Saved Constructions
Store component IDs, order, spacing, slot relationships, annotations, notes, and source tables. Do not save only flattened screenshots.

## Search
Search tables, cards, phrases, notes, and saved constructions. Results must identify source table/category.

## Navigation Philosophy
Support both:
- Immersive navigation through rooms and paintings.
- Expert navigation through hotkeys, favorites, search, table cycling, palette sets, and direct jumps.

## Development Priority
1. Universal table architecture
2. Universal card architecture
3. Color grammar
4. Scan Engine
5. Multi-table workspace
6. Keyboard + mouse workflow
7. Drag/drop construction
8. Row rearrangement
9. Slot frames
10. Notes/annotations
11. Save/load
12. Journal/favorites
13. Archive
14. Castle environments
15. Full content import and visual polish

## MVP Success Test
The prototype succeeds when a user can rapidly load several tables, scan them simultaneously, extract differently categorized cards, rearrange them, create intentional gaps, annotate the result, save it, and switch tables without losing visual momentum.

## Current Scope
The current source collection contains approximately 555 transcribed sticky-note entries plus larger phrase/frame cards. Additional physical tables are still being documented. Missing tables are content work, not architectural blockers.
