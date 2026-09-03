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
        // The category hue tints the whole card body, not just the edge strip.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(color.withValues(alpha: 0.40), const Color(0xFF16191A)),
            Color.alphaBlend(color.withValues(alpha: 0.26), const Color(0xFF16191A)),
          ],
        ),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: color.withValues(alpha: 0.38), width: 1),
          right: BorderSide(color: const Color(0xFF2E3132), width: 1),
          bottom: BorderSide(color: const Color(0xFF2E3132), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: isDragging ? 20 : 8,
            spreadRadius: isDragging ? 2 : 0,
            offset: Offset(0, isDragging ? 8 : 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66F0E6D2), width: 0.8),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
          Expanded(
            child: Text(
              card.text,
              style: const TextStyle(
                color: Color(0xFFF0E6D2),
                fontSize: 14,
                height: 1.25,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (onAddToWall != null && MediaQuery.sizeOf(context).width < 700)
            IconButton(
              tooltip: 'Add to Wall',
              onPressed: onAddToWall,
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
        ],
      ),
    );
  }
}
