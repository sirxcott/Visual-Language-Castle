import 'package:flutter/material.dart';

import '../models/language_card.dart';

class LanguageCardTile extends StatelessWidget {
  const LanguageCardTile({
    super.key,
    required this.card,
    this.onDragStarted,
  });

  final LanguageCard card;
  final VoidCallback? onDragStarted;

  @override
  Widget build(BuildContext context) {
    return Draggable<LanguageCard>(
      data: card,
      onDragStarted: onDragStarted,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 180, child: _CardSurface(card: card, isDragging: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.32, child: _CardSurface(card: card)),
      child: _CardSurface(card: card),
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.card, this.isDragging = false});

  final LanguageCard card;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final color = card.category.color;
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.2), const Color(0xFF191B1C)),
        border: Border(left: BorderSide(color: color, width: 4), top: BorderSide(color: color.withValues(alpha: 0.42))),
        boxShadow: isDragging ? const [BoxShadow(color: Colors.black87, blurRadius: 18)] : null,
      ),
      child: Text(
        card.text,
        style: const TextStyle(color: Color(0xFFE9E0CC), fontSize: 14, height: 1.25),
      ),
    );
  }
}
