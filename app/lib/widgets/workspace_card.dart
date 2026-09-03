import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';

import '../models/language_card.dart';

/// Coloured-paper body for a sticky note.
///
/// The category hue is carried by the paper itself rather than by an accent
/// strip: saturation is kept just below poster-paint level and lightness is
/// spread across the categories so each one reads as its own stock of paper.
/// The lightness is then nudged toward whichever ink it already suits until
/// body text clears WCAG AA, so hue and separation survive the fix.
({Color base, Color ink}) _paperStock(Color category) {
  final hsl = HSLColor.fromColor(category);
  var paper = hsl
      .withSaturation((hsl.saturation * 0.94).clamp(0.30, 0.80))
      .withLightness((hsl.lightness * 0.72 + 0.20).clamp(0.24, 0.80));

  final preferDarkInk = _contrast(paper.toColor(), _darkInk) >= _contrast(paper.toColor(), _lightInk);
  final ink = preferDarkInk ? _darkInk : _lightInk;

  for (var step = 0; step < 40 && _contrast(paper.toColor(), ink) < 5.3; step++) {
    final lightness = (paper.lightness + (preferDarkInk ? 0.02 : -0.02)).clamp(0.0, 1.0);
    if (lightness == paper.lightness) break;
    paper = paper.withLightness(lightness);
  }
  return (base: paper.toColor(), ink: ink);
}

const Color _darkInk = Color(0xFF221A0C);
const Color _lightInk = Color(0xFFFBF4E4);

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (max(first, second) + 0.05) / (min(first, second) + 0.05);
}

/// Category label colour: tinted toward the paper hue but still high contrast.
Color _paperAccent(Color base, Color ink) => Color.lerp(ink, base, 0.18)!;

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
    this.onSettled,
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
  final VoidCallback? onSettled;

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
    final stock = _paperStock(color);
    final base = stock.base;
    final ink = stock.ink;
    final accent = _paperAccent(base, ink);
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
          child: AnimatedSlide(
            offset: Offset(0, _dragging ? -0.05 : 0),
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: AnimatedScale(
              scale: _dragging ? 1.045 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Transform.rotate(
              angle: rotation,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 150, maxWidth: widget.mobile ? 170 : 240),
                child: AnimatedContainer(
                  key: ValueKey('workspace-card-${widget.workspaceCard.instanceId}'),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.55, 1.0],
                      colors: [
                        Color.lerp(base, Colors.white, 0.09)!,
                        base,
                        Color.lerp(base, Colors.black, 0.06)!,
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
                            onTap: widget.connectionMode ? null : widget.onBringToFront,
                            onLongPress: widget.mobile ? widget.onCycleOverlap : null,
                            onPanStart: widget.connectionMode ? null : (_) => setState(() => _dragging = true),
                            onPanUpdate: widget.connectionMode
                                ? null
                                : (details) => widget.onPositionChanged(widget.workspaceCard.position + details.delta),
                            onPanEnd: widget.connectionMode
                                ? null
                                : (_) {
                                    setState(() => _dragging = false);
                                    widget.onSettled?.call();
                                  },
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
                                        border: Border.all(color: ink.withValues(alpha: 0.45), width: 0.8),
                                        boxShadow: [
                                          BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: GestureDetector(
                                        onDoubleTap: widget.connectionMode ? null : widget.onOpenNotes,
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
                                      Icon(Icons.sticky_note_2_outlined, size: 14, color: ink.withValues(alpha: 0.75)),
                                      const SizedBox(width: 4),
                                    ],
                                    if (!widget.connectionMode)
                                      IconButton(
                                        tooltip: 'Remove from wall',
                                        onPressed: widget.onRemove,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                        icon: Text(
                                          '×',
                                          style: TextStyle(
                                            color: ink.withValues(alpha: 0.72),
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
                                  onDoubleTap: widget.connectionMode ? null : widget.onOpenNotes,
                                  child: Text(
                                    card.text,
                                    style: TextStyle(
                                      color: ink,
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
                        if (widget.connectionMode)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onSelectForConnection,
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
      ),
    );
  }
}

