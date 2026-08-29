import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../models/language_card.dart';

class WorkspaceCardTile extends StatelessWidget {
  const WorkspaceCardTile({
    super.key,
    required this.workspaceCard,
    required this.onPositionChanged,
    required this.onOpenNotes,
    required this.onRemove,
    this.mobile = false,
    this.connectionMode = false,
    this.isConnectionStart = false,
    this.onSelectForConnection,
    this.onBringToFront,
    this.onCycleOverlap,
  });

  final WorkspaceCard workspaceCard;
  final ValueChanged<Offset> onPositionChanged;
  final VoidCallback onOpenNotes;
  final VoidCallback onRemove;
  final bool mobile;
  final bool connectionMode;
  final bool isConnectionStart;
  final VoidCallback? onSelectForConnection;
  final VoidCallback? onBringToFront;
  final VoidCallback? onCycleOverlap;

  @override
  Widget build(BuildContext context) {
    final card = workspaceCard.card;
    final color = card.category.color;
    return Positioned(
      left: workspaceCard.position.dx,
      top: workspaceCard.position.dy,
      child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 150, maxWidth: mobile ? 170 : 240),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            decoration: BoxDecoration(
              color: const Color(0xFF202324),
              border: Border.all(color: isConnectionStart ? const Color(0xFFF0E6D2) : color.withValues(alpha: 0.85), width: isConnectionStart ? 2 : 1),
              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTap: onBringToFront,
              onLongPress: mobile ? onCycleOverlap : null,
              onPanUpdate: connectionMode ? null : (details) => onPositionChanged(workspaceCard.position + details.delta),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    GestureDetector(
                      onTap: connectionMode ? onSelectForConnection : null,
                      onDoubleTap: onOpenNotes,
                      child: Text(card.category.label.toUpperCase(), overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 9, letterSpacing: 1.2)),
                    ),
                    const SizedBox(width: 4),
                    if (!connectionMode)
                      IconButton(
                        tooltip: 'Remove from wall',
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                        icon: const Text(
                          '×',
                          style: TextStyle(
                            color: Color(0xFFE0B96B),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    if (workspaceCard.notes.isNotEmpty) const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFFC09A52)),
                  ],
                ),
                const SizedBox(height: 9),
                GestureDetector(
                  onTap: connectionMode ? onSelectForConnection : null,
                  onDoubleTap: onOpenNotes,
                  child: Text(card.text, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 15, height: 1.25)),
                ),
              ],
              ),
            ),
        ),
      ),
    );
  }
}
