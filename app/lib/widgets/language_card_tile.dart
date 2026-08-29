import 'package:flutter/material.dart';

import '../models/language_card.dart';

class LanguageCardTile extends StatelessWidget {
  const LanguageCardTile({
    super.key,
    required this.card,
    this.onDragStarted,
    this.onAddToWall,
  });

  final LanguageCard card;
  final VoidCallback? onDragStarted;
  final VoidCallback? onAddToWall;

  @override
  Widget build(BuildContext context) {
    final surface = _CardSurface(card: card, onAddToWall: onAddToWall);
    if (onAddToWall != null && MediaQuery.sizeOf(context).width < 700) {
      return Row(
        children: [
          Expanded(child: _draggableSurface(_CardSurface(card: card))),
          IconButton(
            tooltip: 'Add to Wall',
            onPressed: onAddToWall,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC09A52), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      );
    }
    return Draggable<LanguageCard>(
      data: card,
      onDragStarted: onDragStarted,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 180, child: _CardSurface(card: card, isDragging: true))),
      childWhenDragging: Opacity(opacity: 0.32, child: surface),
      child: surface,
    );
  }

  Widget _draggableSurface(Widget surface) {
    return Draggable<LanguageCard>(
      data: card,
      onDragStarted: onDragStarted,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 180, child: _CardSurface(card: card, isDragging: true))),
      childWhenDragging: Opacity(opacity: 0.32, child: surface),
      child: surface,
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.card, this.isDragging = false, this.onAddToWall});

  final LanguageCard card;
  final bool isDragging;
  final VoidCallback? onAddToWall;

  @override
  Widget build(BuildContext context) {
    final color = card.category.color;
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Container(
      constraints: BoxConstraints(minHeight: mobile ? 56 : 68),
      padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 14, vertical: mobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.2), const Color(0xFF191B1C)),
        border: Border(left: BorderSide(color: color, width: 4), top: BorderSide(color: color.withValues(alpha: 0.42))),
        boxShadow: isDragging ? const [BoxShadow(color: Colors.black87, blurRadius: 18)] : null,
      ),
      child: Row(
        children: [
          Expanded(child: Text(card.text, style: const TextStyle(color: Color(0xFFE9E0CC), fontSize: 14, height: 1.25))),
          if (onAddToWall != null && MediaQuery.sizeOf(context).width < 700)
            IconButton(tooltip: 'Add to Wall', onPressed: onAddToWall, icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC09A52), size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 28, height: 28)),
        ],
      ),
    );
  }
}
