import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CastleDoorSide { left, right }

class CastleDoor extends StatelessWidget {
  const CastleDoor({
    super.key,
    required this.side,
    required this.progress,
    required this.width,
    required this.height,
  });

  final CastleDoorSide side;
  final double progress;
  final double width;
  final double height;

  // Doors swing open ~80 degrees, hinged at their outer (jamb) edge.
  static const double _maxOpenAngle = 80 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final isLeft = side == CastleDoorSide.left;
    // Pivot stays on the outer jamb edge; center edge swings inward, away
    // from the viewer, so the castle appears to open and invite them in.
    final direction = isLeft ? -1.0 : 1.0;
    return Transform(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateY(direction * _maxOpenAngle * progress),
      child: _DoorSlab(width: width, height: height, isLeft: isLeft),
    );
  }
}

class _DoorSlab extends StatelessWidget {
  const _DoorSlab({required this.width, required this.height, required this.isLeft});

  final double width;
  final double height;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    const brass = Color(0xFFC09A52);
    const brassLight = Color(0xFFD4AF37);
    const brassDark = Color(0xFF705722);
    const ironDark = Color(0xFF121415);
    const ironLight = Color(0xFF33373B);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [
            Color(0xFF180C07),
            Color(0xFF3A1C10),
            Color(0xFF28130B),
            Color(0xFF120704),
          ],
        ),
        border: Border.all(color: brass.withValues(alpha: 0.8), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 24, spreadRadius: 2, offset: Offset(0, 6)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Wood grain texture
          Positioned.fill(child: CustomPaint(painter: _WoodGrainPainter(width: width))),

          // Inset 3D Panels
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                children: [
                  Expanded(child: _DoorPanel(brass: brass, brassLight: brassLight)),
                  const SizedBox(height: 12),
                  Expanded(child: _DoorPanel(brass: brass, brassLight: brassLight)),
                ],
              ),
            ),
          ),

          // Horizontal Iron & Brass Reinforcement Straps (Top, Middle, Bottom)
          for (final factor in [0.12, 0.50, 0.88])
            Positioned(
              top: height * factor - 10,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ironDark, ironLight, ironDark],
                  ),
                  border: Border.symmetric(
                    horizontal: BorderSide(color: brassDark.withValues(alpha: 0.8), width: 1),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [brassLight, brassDark],
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black87, blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Outer Hinge Hardware
          Positioned(
            top: height * 0.18,
            bottom: height * 0.18,
            left: isLeft ? 4 : null,
            right: isLeft ? null : 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                3,
                (_) => Container(
                  width: 8,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ironLight, ironDark, ironLight],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: brassDark.withValues(alpha: 0.6), width: 0.8),
                    boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),

          // Center Meeting Edge Hardware (Lock Plate & Ring Handle)
          Align(
            alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 22,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [brassLight, brass, brassDark],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF100804), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2C1E0A), width: 2.5),
                      color: brassLight,
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Inner Seam Shadow along Meeting Edge
          Align(
            alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 3,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoorPanel extends StatelessWidget {
  const _DoorPanel({required this.brass, required this.brassLight});

  final Color brass;
  final Color brassLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF140804),
            Color(0xFF2A140B),
            Color(0xFF180A05),
          ],
        ),
        border: Border.all(color: brass.withValues(alpha: 0.45), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 6, spreadRadius: -1, offset: Offset(0, 2)),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: brassLight.withValues(alpha: 0.25), width: 0.8),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x333D1F12), Color(0x111F0D07), Color(0x333D1F12)],
          ),
        ),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter({required this.width});

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    // Vertical plank division lines
    final plankPaint = Paint()
      ..color = const Color(0xFF0F0603)
      ..strokeWidth = 1.5;

    final numPlanks = (width / 22.0).clamp(3, 8).toInt();
    for (var i = 1; i < numPlanks; i++) {
      final x = size.width * i / numPlanks;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), plankPaint);
    }

    // Fine organic wood grain
    final grainPaint = Paint()
      ..color = const Color(0x224A2214)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < 14; index++) {
      final y = size.height * (index + 1) / 15;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.5, y + (index.isEven ? 4 : -4), size.width, y + 2);
      canvas.drawPath(path, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter oldDelegate) => oldDelegate.width != width;
}
