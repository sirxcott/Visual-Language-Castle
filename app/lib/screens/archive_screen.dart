import 'package:flutter/material.dart';

import '../models/archived_work.dart';
import '../services/archive_storage.dart';
import 'practice_room_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, this.storage});

  final ArchiveStorage? storage;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
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
        _showStorageError('Unable to load Archive', onRetry: _loadWorks);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _works = works;
      _isLoading = false;
    });
  }

  Future<void> _openWork(ArchivedWork work) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections, sourceWork: work, storage: _storage)));
    _loadWorks();
  }

  void _showStorageError(String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), action: onRetry == null ? null : SnackBarAction(label: 'Retry', onPressed: onRetry)));
  }

  Future<void> _changeCompletion(ArchivedWork work) async {
    final completing = !work.isCompleted;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: Text(completing ? 'Mark as completed?' : 'Return to Archive?'),
        content: Text(completing ? 'Move "${work.name}" into Completed Works?' : 'Mark "${work.name}" as work in progress again?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(completing ? 'Complete' : 'Return')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final proposed = _storage.copyWork(work, isCompleted: completing, completedAt: completing ? DateTime.now() : null, replaceCompletedAt: true);
    final proposedWorks = _storage.replaceWork(_works, proposed);
    try {
      await _storage.saveWorks(proposedWorks);
    } on Object {
      _showStorageError('Unable to update Archive');
      return;
    }
    if (mounted) setState(() => _works = proposedWorks);
  }

  Future<void> _renameWork(ArchivedWork work) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameWorkDialog(initialName: work.name),
    );
    if (!mounted || name == null || name.isEmpty) return;
    final proposed = _storage.copyWork(work, name: name);
    final proposedWorks = _storage.replaceWork(_works, proposed);
    try {
      await _storage.saveWorks(proposedWorks);
    } on Object {
      _showStorageError('Unable to rename archived work');
      return;
    }
    if (mounted) setState(() => _works = proposedWorks);
  }

  Future<void> _deleteWork(ArchivedWork work) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: const Text('Delete archived work?'),
        content: Text('Delete “${work.name}” permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9F4A45)), child: const Text('Delete')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final proposedWorks = List<ArchivedWork>.of(_works)..removeWhere((item) => item.id == work.id);
    try {
      await _storage.saveWorks(proposedWorks);
    } on Object {
      _showStorageError('Unable to delete archived work');
      return;
    }
    if (mounted) setState(() => _works = proposedWorks);
  }

  String _savedDate(DateTime date) {
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
          const CustomPaint(painter: _ArchiveRoomPainter()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                          const Text('ARCHIVE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Archive', style: TextStyle(color: Color(0xFFF5EEDA), fontSize: 38, fontWeight: FontWeight.w400, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      const Text('Saved arrangements from the working wall.', style: TextStyle(color: Color(0xFFC2B7A0), fontSize: 16)),
                      const SizedBox(height: 28),
                      Expanded(child: _buildWorks()),
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

  Widget _buildWorks() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
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
              Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFFD4AF37)),
              SizedBox(height: 12),
              Text('No archived works yet.', style: TextStyle(color: Color(0xFFF5EEDA), fontSize: 17, fontWeight: FontWeight.w500)),
              SizedBox(height: 6),
              Text('Save wall arrangements from the Practice Room to view them here.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _works.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final work = _works[index];
        return _ArchiveItemTile(
          work: work,
          savedDateText: _savedDate(work.savedAt),
          onOpen: () => _openWork(work),
          onToggleComplete: () => _changeCompletion(work),
          onRename: () => _renameWork(work),
          onDelete: () => _deleteWork(work),
        );
      },
    );
  }
}

class _ArchiveItemTile extends StatefulWidget {
  const _ArchiveItemTile({
    required this.work,
    required this.savedDateText,
    required this.onOpen,
    required this.onToggleComplete,
    required this.onRename,
    required this.onDelete,
  });

  final ArchivedWork work;
  final String savedDateText;
  final VoidCallback onOpen;
  final VoidCallback onToggleComplete;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<_ArchiveItemTile> createState() => _ArchiveItemTileState();
}

class _ArchiveItemTileState extends State<_ArchiveItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const brass = Color(0xFFC09A52);
    const gold = Color(0xFFD4AF37);
    final work = widget.work;

    final actions = [
      IconButton(tooltip: 'Open ${work.name}', onPressed: widget.onOpen, icon: Icon(Icons.open_in_new_rounded, color: _hovered ? gold : brass)),
      IconButton(
        tooltip: work.isCompleted ? 'Return "${work.name}" to Archive' : 'Mark "${work.name}" complete',
        onPressed: widget.onToggleComplete,
        icon: Icon(work.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline, color: work.isCompleted ? gold : const Color(0xFF5D9A78)),
      ),
      IconButton(tooltip: 'Rename ${work.name}', onPressed: widget.onRename, icon: const Icon(Icons.edit_outlined, color: Color(0xFFB5ADA0))),
      IconButton(tooltip: 'Delete ${work.name}', onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC4776E))),
    ];

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
            if (work.isCompleted) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5D9A78)),
              const SizedBox(width: 5),
              const Text('Completed', style: TextStyle(color: Color(0xFF5D9A78), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${widget.savedDateText}  ·  ${work.cards.length} cards  ·  ${work.connections.length} ${work.connections.length == 1 ? 'connection' : 'connections'}',
          style: const TextStyle(color: Color(0xFF90887A), fontSize: 12),
        ),
      ],
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
            color: _hovered ? gold : const Color(0xFF645238),
            width: _hovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? gold.withValues(alpha: 0.22) : Colors.black87,
              blurRadius: _hovered ? 14 : 8,
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
                          border: Border.all(color: brass.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Icon(Icons.auto_awesome_mosaic_outlined, color: _hovered ? gold : brass, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(children: actions),
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
                    border: Border.all(color: brass.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Icon(Icons.auto_awesome_mosaic_outlined, color: _hovered ? gold : brass, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: details),
                ...actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArchiveRoomPainter extends CustomPainter {
  const _ArchiveRoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.15,
        colors: const [
          Color(0xFF202223),
          Color(0xFF141617),
          Color(0xFF0A0B0C),
          Color(0xFF040405),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final shelfGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.5),
        radius: 0.8,
        colors: [
          const Color(0xFFD4A325).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shelfGlow);

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

class _RenameWorkDialog extends StatefulWidget {
  const _RenameWorkDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameWorkDialog> createState() => _RenameWorkDialogState();
}

class _RenameWorkDialogState extends State<_RenameWorkDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242627),
      title: const Text('Rename archived work'),
      content: TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(labelText: 'Work name'), onSubmitted: (_) => _submit()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Rename')),
      ],
    );
  }
}
