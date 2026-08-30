import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../models/language_card.dart';

class WorkspaceCardTile extends StatefulWidget {
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
  State<WorkspaceCardTile> createState() => _WorkspaceCardTileState();
}

class _WorkspaceCardTileState extends State<WorkspaceCardTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.workspaceCard.card;
    final color = card.category.color;
    final isStart = widget.isConnectionStart;

    return Positioned(
      left: widget.workspaceCard.position.dx,
      top: widget.workspaceCard.position.dy,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 150, maxWidth: widget.mobile ? 170 : 240),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2021),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isStart
                    ? const Color(0xFFF5D061)
                    : _hovered
                        ? color
                        : color.withValues(alpha: 0.85),
                width: isStart ? 2.5 : (_hovered ? 1.5 : 1.0),
              ),
              boxShadow: [
                if (isStart)
                  const BoxShadow(
                    color: Color(0x88F5D061),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: _hovered ? 18 : 12,
                    offset: Offset(0, _hovered ? 6 : 4),
                  ),
              ],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTap: widget.onBringToFront,
              onLongPress: widget.mobile ? widget.onCycleOverlap : null,
              onPanUpdate: widget.connectionMode
                  ? null
                  : (details) => widget.onPositionChanged(widget.workspaceCard.position + details.delta),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: GestureDetector(
                          onTap: widget.connectionMode ? widget.onSelectForConnection : null,
                          onDoubleTap: widget.onOpenNotes,
                          child: Text(
                            card.category.label.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (widget.workspaceCard.notes.isNotEmpty) ...[
                        const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 4),
                      ],
                      if (!widget.connectionMode)
                        IconButton(
                          tooltip: 'Remove from wall',
                          onPressed: widget.onRemove,
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.connectionMode ? widget.onSelectForConnection : null,
                    onDoubleTap: widget.onOpenNotes,
                    child: Text(
                      card.text,
                      style: const TextStyle(
                        color: Color(0xFFF5EEDA),
                        fontSize: 15,
                        height: 1.25,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
