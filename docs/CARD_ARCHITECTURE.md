# Visual Language Castle — Card Architecture

The app must support more than single-word sticky notes. Cards are reusable linguistic objects with different roles and sizes.

## Universal Card Types

### 1. Content / Nominalization
Concepts, qualities, states, vague terms, resources.

### 2. Verb / Process
Actions and processes.

### 3. Linkage
Short connectors and bridges.

### 4. Compliance Set
Completed reusable phrases or instructions.

### 5. Time Bind
Temporal sequencing or relationship language.

### 6. Cause & Effect Frame
One- or two-slot causal/sequential structures.

### 7. +LY Modifier
Manner modifiers describing how something occurs.

### 8. Hypnotic Question Frame
Question stems that may contain insertion slots.

### 9. Deepener Component
Reusable continuation/deepening phrase elements.

### 10. Pacing / Leading Component
Observable pacing material, bridges, and leading material.

### 11. Things-You-Can-Notice Component
Attentional items intended to follow frames such as `You can notice ___`.

### 12. Unfinished Frame
Intentionally incomplete constructions.

### 13. Resource / Future-Self Quality
Desirable qualities, values, traits, states, and identity characteristics.

### 14. Descriptive Frame
Structures such as `a growing sense of ___` or `a blending of ___ and ___`.

### 15. Blank / Spacer
Intentional empty space. Do not treat as an error.

### 16. User-Created Note Card
A custom card created by the user with text, category, color, tags, and notes.

## Card Sizes
Support at least:
- Small — single word
- Medium — short phrase
- Large — sentence frame
- Slot Frame — one or more embedded drop zones

## Functional Slots
A slot is a drop target inside a larger card.

Example:
`AS YOU [____], YOU [____]`

Inserted cards remain individually editable and retain their own metadata.

## Suggested Card Data Model
Each card should be capable of storing:
- card_id
- visible_text
- card_type
- primary_category
- primary_color
- color_shade
- secondary_tags
- source_table_id
- source_set
- original_number
- original_position
- slot_count
- slot_rules
- use_phase
- instructional_notes
- user_notes
- favorite
- custom

## Personal Notes
Every card may have user-created notes separate from original source content.

Hover may expose a small indicator; click opens an inspector.

## Duplicate Use
The same source card may be instantiated multiple times in a workspace without duplicating the master record.

## Source Integrity
Rearranging a card in a room must never overwrite its original table position, source numbering, or source color metadata.
