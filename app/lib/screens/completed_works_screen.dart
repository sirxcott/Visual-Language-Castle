import 'package:flutter/material.dart';

import '../models/archived_work.dart';
import '../services/archive_storage.dart';
import 'practice_room_screen.dart';

class CompletedWorksScreen extends StatefulWidget {
  const CompletedWorksScreen({super.key, this.storage});

  final ArchiveStorage? storage;

  @override
  State<CompletedWorksScreen> createState() => _CompletedWorksScreenState();
}

class _CompletedWorksScreenState extends State<CompletedWorksScreen> {
  List<ArchivedWork> _works = [];
  bool _isLoading = true;

  ArchiveStorage get _storage => widget.storage ?? ArchiveStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    late final List<ArchivedWork> works;
    try {
      works = await _storage.loadWorks();
    } on Object {
      if (!mounted) return;
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Unable to load Completed Works'), action: SnackBarAction(label: 'Retry', onPressed: _loadWorks)));
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _works = works.where((work) => work.isCompleted).toList();
      _isLoading = false;
    });
  }

  Future<void> _openWork(ArchivedWork work) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work, storage: _storage)));
    _loadWorks();
  }

  String _date(DateTime? date) {
    if (date == null) return 'Completion date unavailable';
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}  ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _CompletedWorksRoomPainter()),
          SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Return to Gallery Hall',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
                            ),
                            const SizedBox(width: 8),
                            const Text('COMPLETED WORKS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3.5)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Completed Works', style: TextStyle(color: Color(0xFFF5EEDA), fontSize: 38, fontWeight: FontWeight.w400, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        const Text('Finished arrangements from your archive.', style: TextStyle(color: Color(0xFFC2B7A0), fontSize: 16)),
                        const SizedBox(height: 28),
                        _buildWorks(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorks() {
    if (_isLoading) return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    if (_works.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF141617).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6E5935).withValues(alpha: 0.6), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.collections_bookmark_outlined, size: 36, color: Color(0xFFD4AF37)),
              SizedBox(height: 12),
              Text('No completed works yet.', style: TextStyle(color: Color(0xFFF5EEDA), fontSize: 17, fontWeight: FontWeight.w500)),
              SizedBox(height: 6),
              Text('Mark archived wall arrangements as completed to showcase them here.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < _works.length; index++) ...[
          _CompletedWorkItem(work: _works[index], completionDate: _date(_works[index].completedAt), onOpen: () => _openWork(_works[index])),
          if (index < _works.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CompletedWorkItem extends StatefulWidget {
  const _CompletedWorkItem({required this.work, required this.completionDate, required this.onOpen});

  final ArchivedWork work;
  final String completionDate;
  final VoidCallback onOpen;

  @override
  State<_CompletedWorkItem> createState() => _CompletedWorkItemState();
}

class _CompletedWorkItemState extends State<_CompletedWorkItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const brass = Color(0xFFC09A52);
    const gold = Color(0xFFD4AF37);
    final work = widget.work;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                work.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _hovered ? const Color(0xFFFFFFFF) : const Color(0xFFF5EEDA),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5D9A78).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF5D9A78), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF5D9A78)),
                  SizedBox(width: 4),
                  Text('FINISHED', style: TextStyle(color: Color(0xFF5D9A78), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Completed: ${widget.completionDate}  ·  ${work.cards.length} cards  ·  ${work.connections.length} ${work.connections.length == 1 ? 'connection' : 'connections'}',
          style: const TextStyle(color: Color(0xFF90887A), fontSize: 12),
        ),
      ],
    );

    final action = IconButton(
      tooltip: 'Open ${work.name}',
      onPressed: widget.onOpen,
      icon: Icon(Icons.open_in_new_rounded, color: _hovered ? gold : brass),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161819),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _hovered ? gold : const Color(0xFF876E43),
            width: _hovered ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? gold.withValues(alpha: 0.28) : Colors.black87,
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 4 : 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101213),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: gold.withValues(alpha: 0.6), width: 1),
                        ),
                        child: Icon(Icons.collections_bookmark_outlined, color: _hovered ? gold : brass, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }
            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101213),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: gold.withValues(alpha: 0.6), width: 1),
                  ),
                  child: Icon(Icons.collections_bookmark_outlined, color: _hovered ? gold : brass, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: details),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletedWorksRoomPainter extends CustomPainter {
  const _CompletedWorksRoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.15,
        colors: const [
          Color(0xFF222425),
          Color(0xFF141617),
          Color(0xFF0A0B0C),
          Color(0xFF040405),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final hallGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 0.8,
        colors: [
          const Color(0xFFD4A325).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, hallGlow);

    final stoneStroke = Paint()
      ..color = const Color(0x182C2822)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const blockHeight = 64.0;
    const blockWidth = 100.0;

    for (var row = 0; row < size.height / blockHeight + 1; row++) {
      final y = row * blockHeight;
      final offset = row.isEven ? 0.0 : blockWidth / 2;
      for (var col = -1; col < size.width / blockWidth + 1; col++) {
        final x = col * blockWidth + offset;
        canvas.drawRect(Rect.fromLTWH(x, y, blockWidth - 2, blockHeight - 2), stoneStroke);
      }
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
        stops: const [0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
