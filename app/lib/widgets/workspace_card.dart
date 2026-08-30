import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';

import '../models/language_card.dart';

/// A believable colored-paper tint blended from the category color over a cream base.
Color _paperBase(Color category) => Color.lerp(const Color(0xFFF6EFDD), category, 0.24)!;

/// A darkened variant of the category color that reads clearly on light paper.
Color _paperAccent(Color category) {
  final hsl = HSLColor.fromColor(category);
  final lightness = hsl.lightness > 0.42 ? 0.34 : hsl.lightness;
  return hsl.withLightness(lightness).toColor();
}

Color _paperEdge(Color base) => Color.lerp(base, Colors.black, 0.16)!;

/// Small deterministic per-card tilt so notes don't look mechanically identical.
double _paperRotation(String instanceId) {
  final seed = instanceId.hashCode;
  return (((seed % 100) - 50) / 50) * 0.018;
}

/// Deterministic, slightly irregular corner radii to avoid a flat digital edge.
BorderRadius _paperRadius(String instanceId) {
  final seed = instanceId.hashCode;
  double jitter(int salt) => 3.5 + ((seed >> salt).abs() % 5);
  return BorderRadius.only(
    topLeft: Radius.circular(jitter(0)),
    topRight: Radius.circular(jitter(4)),
    bottomLeft: Radius.circular(jitter(8)),
    bottomRight: Radius.circular(jitter(12)),
  );
}

/// Lightweight reusable painter for paper grain and a mild corner curl highlight.
class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final grainPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 22; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.4 + random.nextDouble() * 0.9;
      final alpha = 0.02 + random.nextDouble() * 0.05;
      grainPaint.color = (random.nextBool() ? Colors.black : Colors.white).withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), radius, grainPaint);
    }
    final curlSize = size.width * 0.22;
    final curlRect = seed.isEven
        ? Rect.fromLTWH(size.width - curlSize, 0, curlSize, curlSize)
        : Rect.fromLTWH(0, size.height - curlSize, curlSize, curlSize);
    final curlPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.0)],
      ).createShader(curlRect);
    canvas.drawRect(curlRect, curlPaint);
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) => oldDelegate.seed != seed;
}

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
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.workspaceCard.card;
    final color = card.category.color;
    final isStart = widget.isConnectionStart;
    final base = _paperBase(color);
    final accent = _paperAccent(color);
    final radius = _paperRadius(widget.workspaceCard.instanceId);
    final rotation = widget.connectionMode ? 0.0 : _paperRotation(widget.workspaceCard.instanceId);
    final lifted = _dragging || _hovered;

    return Positioned(
      left: widget.workspaceCard.position.dx,
      top: widget.workspaceCard.position.dy,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: RepaintBoundary(
          child: AnimatedScale(
            scale: _dragging ? 1.045 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Transform.rotate(
              angle: rotation,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 150, maxWidth: widget.mobile ? 170 : 240),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.55, 1.0],
                      colors: [
                        Color.lerp(base, Colors.white, 0.05)!,
                        base,
                        Color.lerp(base, Colors.black, 0.05)!,
                      ],
                    ),
                    border: Border.all(
                      color: isStart
                          ? const Color(0xFFF5D061)
                          : _hovered
                              ? accent
                              : _paperEdge(base).withValues(alpha: 0.55),
                      width: isStart ? 2.5 : (_hovered ? 1.4 : 0.8),
                    ),
                    boxShadow: [
                      if (isStart)
                        const BoxShadow(color: Color(0x88F5D061), blurRadius: 16, spreadRadius: 2)
                      else ...[
                        BoxShadow(color: Colors.black.withValues(alpha: lifted ? 0.32 : 0.24), blurRadius: lifted ? 8 : 5, offset: Offset(0, lifted ? 3 : 2)),
                        BoxShadow(color: Colors.black.withValues(alpha: lifted ? 0.28 : 0.18), blurRadius: lifted ? 26 : 14, offset: Offset(0, lifted ? 14 : 7)),
                      ],
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: _PaperGrainPainter(seed: widget.workspaceCard.instanceId.hashCode)),
                          ),
                        ),
                        Positioned(
                          top: -3,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 9,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            dragStartBehavior: DragStartBehavior.down,
                            onTap: widget.onBringToFront,
                            onLongPress: widget.mobile ? widget.onCycleOverlap : null,
                            onPanStart: widget.connectionMode ? null : (_) => setState(() => _dragging = true),
                            onPanUpdate: widget.connectionMode
                                ? null
                                : (details) => widget.onPositionChanged(widget.workspaceCard.position + details.delta),
                            onPanEnd: widget.connectionMode ? null : (_) => setState(() => _dragging = false),
                            onPanCancel: widget.connectionMode ? null : () => setState(() => _dragging = false),
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
                                            color: accent,
                                            fontSize: 9,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (widget.workspaceCard.notes.isNotEmpty) ...[
                                      const Icon(Icons.sticky_note_2_outlined, size: 14, color: Color(0xFFAD7F1E)),
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
                                            color: Color(0xFF8B6B1F),
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
                                      color: Color(0xFF2E2414),
                                      fontSize: 15,
                                      height: 1.25,
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

