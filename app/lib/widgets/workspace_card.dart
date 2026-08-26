import 'package:flutter/material.dart';

import '../models/language_card.dart';

class WorkspaceCardTile extends StatelessWidget {
  const WorkspaceCardTile({
    super.key,
    required this.workspaceCard,
    required this.onPositionChanged,
    required this.onOpenNotes,
  });

  final WorkspaceCard workspaceCard;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    final card = workspaceCard.card;
    final color = card.category.color;
    return Positioned(
      left: workspaceCard.position.dx,
      top: workspaceCard.position.dy,
      child: GestureDetector(
        onDoubleTap: onOpenNotes,
        onPanUpdate: (details) => onPositionChanged(workspaceCard.position + details.delta),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            decoration: BoxDecoration(
              color: const Color(0xFF202324),
              border: Border.all(color: color.withValues(alpha: 0.85)),
              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Expanded(child: Text(card.category.label.toUpperCase(), overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 9, letterSpacing: 1.2))),
                    if (workspaceCard.notes.isNotEmpty) const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFFC09A52)),
                  ],
                ),
                const SizedBox(height: 9),
                Text(card.text, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 15, height: 1.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
