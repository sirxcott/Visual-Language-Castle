import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/language_card.dart';
import '../models/language_table.dart';
import 'language_card_tile.dart';

class TableBrowser extends StatelessWidget {
  const TableBrowser({
    super.key,
    required this.table,
    required this.tableIndex,
    required this.tableCount,
    required this.onPrevious,
    required this.onNext,
    this.onAddCard,
  });

  final LanguageTable table;
  final int tableIndex;
  final int tableCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<LanguageCard>? onAddCard;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final wallCards = table.cards
        .where((card) => !card.isResearchOnly)
        .toList();
    return SizedBox(
      width: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _TableBrowserWoodSurroundPainter()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  mobile ? 10 : 18,
                  12,
                  mobile ? 6 : 12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TABLE BROWSER',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tableIndex + 1} / $tableCount',
                      style: const TextStyle(
                        color: Color(0xFF2E2214),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: Color(0x88F5EEDA), blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous table (A)',
                      onPressed: onPrevious,
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        table.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF5EEDA),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next table (D)',
                      onPressed: onNext,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
              if (_tableGuidance.containsKey(table.name))
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      tooltip: 'Open table guidance',
                      onPressed: () => _showTableGuidance(context),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
              Divider(color: const Color(0xFF3A2B1A), height: mobile ? 10 : 20),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(14, 0, 14, mobile ? 10 : 20),
                  itemCount: wallCards.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 9),
                  itemBuilder: (context, index) => LanguageCardTile(
                    card: wallCards[index],
                    onAddToWall: onAddCard == null
                        ? null
                        : () => onAddCard!(wallCards[index]),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, mobile ? 8 : 18),
                child: const Text(
                  'Drag a card onto the wall.\nA / D changes tables quickly.',
                  style: TextStyle(
                    color: Color(0xFF2C1E11),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Color(0x66F5EEDA), blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTableGuidance(BuildContext context) {
    final guidance = _tableGuidance[table.name];
    if (guidance == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1D1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF876E43), width: 1.5),
        ),
        title: Text(
          table.name,
          style: const TextStyle(
            color: Color(0xFFF5EEDA),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: guidance,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static const _tableGuidance = <String, List<Widget>>{
    'Nominals': [
      Text(
        'Nominals are the abbreviated app term for hypnotic nominalizations.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
    ],
    'Verbs': [
      Text(
        'Verbs are single root process words naming fundamental internal actions or processes. Longer functional phrases belong in specialized Tables.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
    ],
    'TRANCE WORDPLAY': [
      Text(
        'Trance Wordplay uses phonetic puns, homophones, and prefix substitutions (such as "Trance-" for "trans-") to create double meanings and unconscious associations.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
    ],
    'Compliance Commands': [
      Text(
        'These are individual low-effort commands used to obtain or maintain easy compliance and hypnotic momentum. They may later be classified as Voluntary or Involuntary Compliance. A single command is NOT a Compliance Set.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
    ],
    'Compliance Sets': [
      Text(
        'A Compliance Set is three or more Compliance Commands given one after another. Fewer than three commands does not constitute a set. The sequence should flow naturally as a unit. This table is intentionally empty until approved sets are added.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
    ],
    'Linkages': [
      Text(
        'Linkages are spoken transition structures that maintain and shape hypnotic/conversational momentum.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
      SizedBox(height: 16),
      Text(
        'BASIC LINKAGES',
        style: TextStyle(
          color: Color(0xFFC09A52),
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
      SizedBox(height: 5),
      Text(
        'Simple connective scaffolding joining statements.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
      SizedBox(height: 14),
      Text(
        'RESTATEMENT LINKAGES',
        style: TextStyle(
          color: Color(0xFFC09A52),
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
      SizedBox(height: 5),
      Text(
        'Structures used to restate or rephrase an idea while maintaining flow.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
      SizedBox(height: 14),
      Text(
        'MOMENTUM LINKAGES',
        style: TextStyle(
          color: Color(0xFFC09A52),
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
      SizedBox(height: 5),
      Text(
        'Structures used to maintain or propel conversational/hypnotic momentum.',
        style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4),
      ),
    ],
  };
}

class _TableBrowserWoodSurroundPainter extends CustomPainter {
  const _TableBrowserWoodSurroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Natural Light-Golden/Tan Medieval Wood Base Gradient
    final baseGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF9E7D4E),
          Color(0xFFA68553),
          Color(0xFF8E6F42),
          Color(0xFF9B7B4A),
          Color(0xFF87693E),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, baseGradient);

    // 2. Horizontal Plank Divisions and Organic Per-Plank Color Shading
    const plankHeight = 52.0;
    final numPlanks = (size.height / plankHeight).ceil() + 1;

    for (var i = 0; i < numPlanks; i++) {
      final yTop = i * plankHeight;
      final yBottom = yTop + plankHeight;
      final plankRect = Rect.fromLTRB(0, yTop, size.width, yBottom);

      // Subtle organic color variance between individual planks
      final seed = math.sin(i * 12.9898 + 4.123) * 43758.5453;
      final variance = (seed - seed.floor()) - 0.5;

      final plankOverlayPaint = Paint()
        ..color = variance > 0
            ? Color(0xFFC49A65)
                  .withValues(alpha: (variance * 0.12).clamp(0.0, 0.12))
            : Color(0xFF4A3319)
                  .withValues(alpha: (-variance * 0.14).clamp(0.0, 0.14));
      canvas.drawRect(plankRect, plankOverlayPaint);

      // Organic horizontal wood grain lines on this plank
      _drawPlankGrain(canvas, plankRect, i);

      // Plank horizontal joint division lines (dark groove + subtle bottom highlight)
      if (i > 0 && yTop < size.height) {
        final groovePaint = Paint()
          ..color = const Color(0xFF2B1C0E).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(0, yTop), Offset(size.width, yTop), groovePaint);

        final highlightPaint = Paint()
          ..color = const Color(0xFFD3B083).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(0, yTop + 1.2),
          Offset(size.width, yTop + 1.2),
          highlightPaint,
        );
      }
    }

    // 3. Restrained Natural Knots on select planks
    _drawKnot(canvas, Offset(size.width * 0.35, plankHeight * 2.4));
    _drawKnot(canvas, Offset(size.width * 0.72, plankHeight * 6.8));
    _drawKnot(canvas, Offset(size.width * 0.22, plankHeight * 11.2));

    // 4. Subtle Ambient Corner / Inner Shading (Wood Depth)
    final innerShadow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0),
        radius: 1.1,
        colors: [
          Colors.transparent,
          const Color(0xFF261A0E).withValues(alpha: 0.30),
        ],
        stops: const [0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, innerShadow);

    // 5. Dark Timber & Iron Outer Framing
    final frameBorderPaint = Paint()
      ..color = const Color(0xFF24170D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(rect.deflate(1.5), frameBorderPaint);

    // Right-edge iron timber trim line
    final ironTrimPaint = Paint()
      ..color = const Color(0xFF3E3123)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width - 1.0, 0),
      Offset(size.width - 1.0, size.height),
      ironTrimPaint,
    );

    final ironDetailPaint = Paint()
      ..color = const Color(0xFF1B140B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.width - 2.5, 0),
      Offset(size.width - 2.5, size.height),
      ironDetailPaint,
    );
  }

  void _drawPlankGrain(Canvas canvas, Rect plankRect, int plankIndex) {
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const numLines = 4;
    for (var l = 0; l < numLines; l++) {
      final yRatio = (l + 1) / (numLines + 1);
      final baseY = plankRect.top + plankRect.height * yRatio;

      final waveOffset1 = math.sin((plankIndex * 7 + l) * 0.9) * 2.5;
      final waveOffset2 = math.cos((plankIndex * 5 + l) * 1.3) * 2.5;

      final path = Path()
        ..moveTo(0, baseY + waveOffset1)
        ..cubicTo(
          plankRect.width * 0.35,
          baseY + waveOffset1 - 1.8,
          plankRect.width * 0.65,
          baseY + waveOffset2 + 1.8,
          plankRect.width,
          baseY + waveOffset2,
        );

      final isDark = l.isEven;
      grainPaint.color = isDark
          ? const Color(0xFF2A1A0D).withValues(alpha: 0.24)
          : const Color(0xFFD8B588).withValues(alpha: 0.15);
      grainPaint.strokeWidth = 0.9 + (l % 2) * 0.4;

      canvas.drawPath(path, grainPaint);
    }
  }

  void _drawKnot(Canvas canvas, Offset center) {
    final outerRing = Paint()
      ..color = const Color(0xFF382312).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 22.0, height: 11.0),
      outerRing,
    );

    final innerRing = Paint()
      ..color = const Color(0xFF2B1B0D).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 14.0, height: 7.0),
      innerRing,
    );

    final corePaint = Paint()
      ..color = const Color(0xFF221308).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 7.0, height: 4.0),
      corePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TableBrowserWoodSurroundPainter oldDelegate) =>
      false;
}
