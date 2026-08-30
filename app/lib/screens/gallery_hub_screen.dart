import 'package:flutter/material.dart';

import 'archive_screen.dart';
import 'completed_works_screen.dart';
import 'practice_room_screen.dart';
import 'research_laboratory_screen.dart';

class GalleryHubScreen extends StatelessWidget {
  const GalleryHubScreen({super.key});

  static const destinations = [
    ('Practice Rooms', Icons.auto_stories_outlined, 'Construct and manipulate language structures on the Working Wall.'),
    ('Archive', Icons.inventory_2_outlined, 'Review, manage, and restore saved wall arrangements.'),
    ('Research Laboratory', Icons.science_outlined, 'Search, filter, and analyze the language corpus across all tables.'),
    ('Completed Works', Icons.collections_bookmark_outlined, 'Examine finalized language compositions and past achievements.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _GalleryHallPainter()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THE INNER GALLERY',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.5,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gallery Hall',
                        style: TextStyle(
                          color: Color(0xFFF5EEDA),
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A first glimpse into the rooms beyond the entrance.',
                        style: TextStyle(
                          color: Color(0xFFC2B7A0),
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 440,
                            mainAxisExtent: 180,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: destinations.length,
                          itemBuilder: (context, index) {
                            final destination = destinations[index];
                            final title = destination.$1;
                            final icon = destination.$2;
                            final description = destination.$3;
                            return _GalleryFrame(
                              title: title,
                              icon: icon,
                              description: description,
                              onTap: title == 'Practice Rooms'
                                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PracticeRoomScreen()))
                                : title == 'Archive'
                                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArchiveScreen()))
                                : title == 'Research Laboratory'
                                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ResearchLaboratoryScreen()))
                                : title == 'Completed Works'
                                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CompletedWorksScreen()))
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryFrame extends StatefulWidget {
  const _GalleryFrame({
    required this.title,
    required this.icon,
    required this.description,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String description;
  final VoidCallback? onTap;

  @override
  State<_GalleryFrame> createState() => _GalleryFrameState();
}

class _GalleryFrameState extends State<_GalleryFrame> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const brass = Color(0xFFC09A52);
    const gold = Color(0xFFD4AF37);

    return Semantics(
      button: widget.onTap != null,
      label: widget.onTap == null ? widget.title : 'Open ${widget.title}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translateByDouble(0, _hovered ? -4.0 : 0.0, 0, 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? gold : brass.withValues(alpha: 0.8),
              width: _hovered ? 2.0 : 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hovered
                  ? const [Color(0xFF26292B), Color(0xFF191B1C)]
                  : const [Color(0xFF1E2021), Color(0xFF121415)],
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? gold.withValues(alpha: 0.35) : Colors.black87,
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                // Icon Frame Plaque
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121314),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: brass.withValues(alpha: 0.5), width: 1),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      color: _hovered ? gold : brass,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and Description
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: _hovered ? const Color(0xFFFFFFFF) : const Color(0xFFF5EEDA),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA9A294),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _hovered ? gold : brass.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryHallPainter extends CustomPainter {
  const _GalleryHallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Base atmospheric gradient
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.1),
        radius: 1.2,
        colors: const [
          Color(0xFF222425),
          Color(0xFF141617),
          Color(0xFF090A0B),
          Color(0xFF040405),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Warm sconce light glow from upper left and upper right
    final leftSconce = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 0.6,
        colors: [
          const Color(0xFFD4A325).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, leftSconce);

    final rightSconce = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 0.6,
        colors: [
          const Color(0xFFD4A325).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, rightSconce);

    // Subtle stone coursing lines
    final stoneStroke = Paint()
      ..color = const Color(0x182A2722)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const blockHeight = 68.0;
    const blockWidth = 110.0;

    for (var row = 0; row < size.height / blockHeight + 1; row++) {
      final y = row * blockHeight;
      final offset = row.isEven ? 0.0 : blockWidth / 2;
      for (var col = -1; col < size.width / blockWidth + 1; col++) {
        final x = col * blockWidth + offset;
        canvas.drawRect(Rect.fromLTWH(x, y, blockWidth - 2, blockHeight - 2), stoneStroke);
      }
    }

    // Outer vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.80)],
        stops: const [0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
