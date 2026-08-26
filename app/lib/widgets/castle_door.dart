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

  @override
  Widget build(BuildContext context) {
    final isLeft = side == CastleDoorSide.left;
    final direction = isLeft ? -1.0 : 1.0;
    return Transform(
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..translateByDouble(direction * width * 0.72 * progress, 0, 0, 1)
        ..rotateY(direction * progress),
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [Color(0xFF3A2117), Color(0xFF6B3921), Color(0xFF2A1712)],
        ),
        border: Border.all(color: brass.withValues(alpha: 0.72), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 22, spreadRadius: 3)],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WoodGrainPainter())),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: brass.withValues(alpha: 0.65), width: 1.5)),
                child: Column(
                  children: [
                    Expanded(child: _DoorPanel(color: brass)),
                    const SizedBox(height: 12),
                    Expanded(child: _DoorPanel(color: brass)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: height * 0.25,
            bottom: height * 0.25,
            left: isLeft ? 10 : null,
            right: isLeft ? null : 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                3,
                (_) => Container(
                  width: 9,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brass,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: brass,
                  boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 5)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoorPanel extends StatelessWidget {
  const _DoorPanel({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        gradient: const LinearGradient(colors: [Color(0x44301912), Color(0x113D2015), Color(0x44301912)]),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x3320100C)..strokeWidth = 1.2;
    for (var index = 0; index < 12; index++) {
      final y = size.height * (index + 1) / 13;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
