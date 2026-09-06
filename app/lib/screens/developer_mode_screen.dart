import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/developer_board.dart';
import '../services/developer_board_storage.dart';

class DeveloperModeScreen extends StatefulWidget {
  const DeveloperModeScreen({super.key, this.storage});

  final DeveloperBoardStorage? storage;

  @override
  State<DeveloperModeScreen> createState() => _DeveloperModeScreenState();
}

class _DeveloperModeScreenState extends State<DeveloperModeScreen> {
  final List<DeveloperNote> _notes = [];
  final List<DeveloperConnection> _connections = [];
  String _boardName = 'Untitled Development';
  String _boardId = '';
  DateTime _savedAt = DateTime.now();
  List<DeveloperBoard> _savedBoards = [];
  bool _loading = true;
  bool _connectionMode = false;
  String? _connectionStartId;
  double _zoom = 1.0;
  BoxConstraints? _workSurface;

  DeveloperBoardStorage get _storage => widget.storage ?? DeveloperBoardStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    final boards = await _storage.loadBoards();
    if (mounted) {
      setState(() {
        _savedBoards = boards;
        _loading = false;
      });
    }
  }

  void _addNote() {
    final index = _notes.length;
    setState(
      () => _notes.add(
        DeveloperNote(
          id: 'developer-${DateTime.now().microsecondsSinceEpoch}-$index',
          text: '',
          researchNotes: '',
          colorValue: DeveloperCategory.values[index % (DeveloperCategory.values.length - 1)].color.toARGB32(),
          category: DeveloperCategory.values[index % (DeveloperCategory.values.length - 1)],
          position: Offset(32.0 + (index % 4) * 42, 36.0 + (index % 5) * 34),
        ),
      ),
    );
  }

  void _deleteNote(DeveloperNote note) {
    setState(() {
      _notes.removeWhere((item) => item.id == note.id);
      _connections.removeWhere((connection) => connection.fromNoteId == note.id || connection.toNoteId == note.id);
      if (_connectionStartId == note.id) _connectionStartId = null;
    });
  }

  void _moveNote(DeveloperNote note, Offset delta) {
    final bounds = _workSurface;
    if (bounds == null) return;
    setState(() {
      note.position = Offset(
        (note.position.dx + delta.dx).clamp(0.0, math.max(0.0, bounds.maxWidth - 220)),
        (note.position.dy + delta.dy).clamp(0.0, math.max(0.0, bounds.maxHeight - 150)),
      );
    });
  }

  void _toggleConnectionMode() {
    setState(() {
      _connectionMode = !_connectionMode;
      _connectionStartId = null;
    });
  }

  void _selectNoteForConnection(DeveloperNote note) {
    if (!_connectionMode) return;
    setState(() {
      if (_connectionStartId == null) {
        _connectionStartId = note.id;
        return;
      }
      if (_connectionStartId == note.id) {
        _connectionStartId = null;
        return;
      }
      final exists = _connections.any(
        (connection) => connection.fromNoteId == _connectionStartId && connection.toNoteId == note.id,
      );
      if (!exists) {
        _connections.add(DeveloperConnection(fromNoteId: _connectionStartId!, toNoteId: note.id));
      }
      _connectionStartId = null;
    });
  }

  void _removeConnectionAt(Offset point) {
    if (!_connectionMode) return;
    for (var index = _connections.length - 1; index >= 0; index--) {
      final connection = _connections[index];
      final fromMatches = _notes.where((note) => note.id == connection.fromNoteId);
      final toMatches = _notes.where((note) => note.id == connection.toNoteId);
      if (fromMatches.isEmpty || toMatches.isEmpty) continue;
      final segment = _connectionSegment(fromMatches.first, toMatches.first);
      if (_distanceToSegment(point, segment.start, segment.end) < 14) {
        setState(() => _connections.removeAt(index));
        return;
      }
    }
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final delta = end - start;
    final lengthSquared = delta.dx * delta.dx + delta.dy * delta.dy;
    if (lengthSquared == 0) return (point - start).distance;
    final projection = ((point.dx - start.dx) * delta.dx + (point.dy - start.dy) * delta.dy) / lengthSquared;
    final t = projection.clamp(0.0, 1.0);
    final closest = Offset(start.dx + delta.dx * t, start.dy + delta.dy * t);
    return (point - closest).distance;
  }

  Future<void> _editResearch(DeveloperNote note) async {
    final controller = TextEditingController(text: note.researchNotes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: 'Notes / Research',
        label: 'Secondary notes',
        controller: controller,
        action: 'Save notes',
        maxLines: 8,
      ),
    );
    controller.dispose();
    if (result != null) setState(() => note.researchNotes = result);
  }

  Future<void> _chooseColor(DeveloperNote note) async {
    final selected = await showDialog<DeveloperCategory>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sticky category'),
        content: SizedBox(
          width: 420,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in DeveloperCategory.values.where((category) => category != DeveloperCategory.unknown))
                _CategoryChoice(
                  category: category,
                  selected: category == note.category,
                  onTap: () => Navigator.pop(context, category),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) setState(() => note.category = selected);
  }

  Future<void> _saveBoard() async {
    final controller = TextEditingController(text: _boardName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(
        title: 'Save Developer Board',
        label: 'Board name',
        controller: controller,
        action: 'Save board',
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final now = DateTime.now();
    final board = DeveloperBoard(
      id: _boardId.isEmpty ? now.microsecondsSinceEpoch.toString() : _boardId,
      name: name,
      savedAt: now,
      notes: _notes.map((note) => note.copy()).toList(),
      connections: List<DeveloperConnection>.of(_connections),
    );
    final boards = List<DeveloperBoard>.of(_savedBoards);
    final existing = boards.indexWhere((item) => item.id == board.id);
    if (existing >= 0) {
      boards[existing] = board;
    } else {
      boards.insert(0, board);
    }
    await _storage.saveBoards(boards);
    if (mounted) {
      setState(() {
        _boardId = board.id;
        _boardName = board.name;
        _savedAt = board.savedAt;
        _savedBoards = boards;
      });
    }
  }

  Future<void> _openBoard() async {
    final board = await showDialog<DeveloperBoard>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Developer Board'),
        content: SizedBox(
          width: 440,
          child: _savedBoards.isEmpty
              ? const Text('No Developer Mode boards have been saved yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _savedBoards.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _savedBoards[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.notes.length} notes · ${item.connections.length} arrows'),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
        ),
      ),
    );
    if (board != null) {
      setState(() {
        _boardId = board.id;
        _boardName = board.name;
        _savedAt = board.savedAt;
        _notes
          ..clear()
          ..addAll(board.notes.map((note) => note.copy()));
        _connections
          ..clear()
          ..addAll(board.connections);
        _connectionMode = false;
        _connectionStartId = null;
      });
    }
  }

  void _exportBoard() {
    final board = DeveloperBoard(
      id: _boardId,
      name: _boardName,
      savedAt: _savedAt,
      notes: _notes.map((note) => note.copy()).toList(),
      connections: List<DeveloperConnection>.of(_connections),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Board'),
        content: SizedBox(width: 560, child: SelectableText(_storage.exportBoard(board))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _TowerPainter()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _DeveloperToolbar(
                    boardName: _boardName,
                    onBack: () => Navigator.pop(context),
                    onAdd: _addNote,
                    onSave: _saveBoard,
                    onOpen: _openBoard,
                    onExport: _exportBoard,
                    connectionMode: _connectionMode,
                    onToggleConnections: _toggleConnectionMode,
                    zoom: _zoom,
                    onZoomChanged: (value) => setState(() => _zoom = value),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final logicalWidth = constraints.maxWidth / _zoom;
                        final logicalHeight = constraints.maxHeight / _zoom;
                        _workSurface = BoxConstraints(maxWidth: logicalWidth, maxHeight: logicalHeight);
                        return Container(
                          key: const ValueKey('developer-work-surface'),
                          decoration: BoxDecoration(
                            color: const Color(0xDD16191A),
                            border: Border.all(color: const Color(0xFF80643A), width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 22)],
                          ),
                          child: ClipRect(
                            child: Transform.scale(
                              scale: _zoom,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: logicalWidth,
                                height: logicalHeight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: _connectionMode ? (details) => _removeConnectionAt(details.localPosition) : null,
                                  child: Stack(
                                    children: [
                                      const Positioned(
                                        left: 20,
                                        top: 18,
                                        child: Text(
                                          'THE ALCHEMIST\'S WORKBENCH',
                                          style: TextStyle(
                                            color: Color(0xFFC09A52),
                                            fontSize: 10,
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (_connectionMode)
                                        const Positioned(
                                          right: 20,
                                          top: 16,
                                          child: Text(
                                            'CONNECTION MODE · tap one sticky, then another · tap an arrow to remove',
                                            style: TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 9,
                                              letterSpacing: 0.7,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      if (!_loading && _notes.isEmpty)
                                        const Center(
                                          child: Text(
                                            'Create a note to begin developing a structure.',
                                            style: TextStyle(color: Color(0xFFA9A294), fontSize: 16),
                                          ),
                                        ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            painter: _DeveloperConnectionsPainter(
                                              notes: _notes,
                                              connections: _connections,
                                            ),
                                          ),
                                        ),
                                      ),
                                      ..._notes.map(
                                        (note) => _DeveloperStickyNote(
                                          note: note,
                                          onChanged: () => setState(() {}),
                                          onMove: (delta) => _moveNote(note, delta),
                                          onDelete: () => _deleteNote(note),
                                          onResearch: () => _editResearch(note),
                                          onColor: () => _chooseColor(note),
                                          connectionMode: _connectionMode,
                                          isConnectionStart: _connectionStartId == note.id,
                                          onSelectForConnection: () => _selectNoteForConnection(note),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperToolbar extends StatelessWidget {
  const _DeveloperToolbar({
    required this.boardName,
    required this.onBack,
    required this.onAdd,
    required this.onSave,
    required this.onOpen,
    required this.onExport,
    required this.connectionMode,
    required this.onToggleConnections,
    required this.zoom,
    required this.onZoomChanged,
  });

  final String boardName;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onExport;
  final bool connectionMode;
  final VoidCallback onToggleConnections;
  final double zoom;
  final ValueChanged<double> onZoomChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: 'Return to Gallery Hall',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
          ),
          Text(
            'DEVELOPER MODE  |  $boardName',
            style: const TextStyle(
              color: Color(0xFFF5EEDA),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('New Sticky')),
          OutlinedButton.icon(onPressed: onSave, icon: const Icon(Icons.save_outlined), label: const Text('Save Board')),
          OutlinedButton.icon(onPressed: onOpen, icon: const Icon(Icons.folder_open_outlined), label: const Text('Open Board')),
          OutlinedButton.icon(onPressed: onExport, icon: const Icon(Icons.ios_share_outlined), label: const Text('Export Board')),
          OutlinedButton.icon(
            key: const ValueKey('developer-connections-button'),
            onPressed: onToggleConnections,
            style: OutlinedButton.styleFrom(
              backgroundColor: connectionMode ? const Color(0x443E6A80) : null,
              foregroundColor: connectionMode ? const Color(0xFFD4AF37) : null,
              side: BorderSide(color: connectionMode ? const Color(0xFFD4AF37) : const Color(0xFF80643A)),
            ),
            icon: Icon(connectionMode ? Icons.alt_route_rounded : Icons.call_made_rounded),
            label: Text(connectionMode ? 'Connections: ON' : 'Connections'),
          ),
          _ZoomControl(zoom: zoom, onChanged: onZoomChanged),
        ],
      );
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({required this.zoom, required this.onChanged});

  final double zoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const step = 0.05;
    return Container(
      key: const ValueKey('developer-zoom-control'),
      width: 220,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0x55121516),
        border: Border.all(color: const Color(0xFF80643A)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed: zoom > 0.55 ? () => onChanged((zoom - step).clamp(0.55, 1.0)) : null,
            icon: const Icon(Icons.remove_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Slider(
              value: zoom,
              min: 0.55,
              max: 1.0,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(zoom * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD8CFBC), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: zoom < 1.0 ? () => onChanged((zoom + step).clamp(0.55, 1.0)) : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _DeveloperStickyNote extends StatefulWidget {
  const _DeveloperStickyNote({
    required this.note,
    required this.onChanged,
    required this.onMove,
    required this.onDelete,
    required this.onResearch,
    required this.onColor,
    required this.connectionMode,
    required this.isConnectionStart,
    required this.onSelectForConnection,
  });

  final DeveloperNote note;
  final VoidCallback onChanged;
  final ValueChanged<Offset> onMove;
  final VoidCallback onDelete;
  final VoidCallback onResearch;
  final VoidCallback onColor;
  final bool connectionMode;
  final bool isConnectionStart;
  final VoidCallback onSelectForConnection;

  @override
  State<_DeveloperStickyNote> createState() => _DeveloperStickyNoteState();
}

class _DeveloperStickyNoteState extends State<_DeveloperStickyNote> {
  late final TextEditingController _controller = TextEditingController(text: widget.note.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.note.color;
    return Positioned(
      left: widget.note.position.dx,
      top: widget.note.position.dy,
      child: SizedBox(
        width: 210,
        height: 145,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Container(
                key: ValueKey('developer-note-${widget.note.id}'),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.isConnectionStart ? const Color(0xFFFFE082) : Colors.white.withValues(alpha: 0.35),
                    width: widget.isConnectionStart ? 3 : 1,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(2, 5))],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onPanUpdate: widget.connectionMode ? null : (details) => widget.onMove(details.delta),
                      child: Container(
                        height: 27,
                        color: Colors.black.withValues(alpha: 0.18),
                        child: Row(
                          children: [
                            const SizedBox(width: 7),
                            const Icon(Icons.drag_indicator_rounded, size: 17, color: Color(0xDD21170C)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.note.category.label.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF21170C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Note color',
                              onPressed: widget.connectionMode ? null : widget.onColor,
                              icon: const Icon(Icons.palette_outlined, size: 17),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                            ),
                            IconButton(
                              tooltip: 'Notes / Research',
                              onPressed: widget.connectionMode ? null : widget.onResearch,
                              icon: const Icon(Icons.menu_book_outlined, size: 17),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                            ),
                            IconButton(
                              tooltip: 'Delete sticky',
                              onPressed: widget.connectionMode ? null : widget.onDelete,
                              icon: const Icon(Icons.close, size: 17),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: LayoutBuilder(
                          builder: (context, constraints) => TextField(
                            key: ValueKey('developer-note-text-${widget.note.id}'),
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            enabled: !widget.connectionMode,
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (value) {
                              widget.note.text = value;
                              widget.onChanged();
                            },
                            style: TextStyle(
                              color: const Color(0xFF21170C),
                              fontWeight: FontWeight.w600,
                              fontSize: _fitFont(_controller.text, constraints),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Type a language structure...',
                              hintStyle: TextStyle(color: Color(0x8821170C)),
                              disabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.connectionMode)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('developer-connection-target-${widget.note.id}'),
                      onTap: widget.onSelectForConnection,
                      borderRadius: BorderRadius.circular(4),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            widget.isConnectionStart ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 17,
                            color: const Color(0xFF5B4218),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _fitFont(String text, BoxConstraints constraints) {
    for (var size = 17.0; size >= 9; size -= 1) {
      final painter = TextPainter(
        text: TextSpan(
          text: text.isEmpty ? 'Type a language structure...' : text,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
        ),
        maxLines: null,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);
      if (painter.height <= constraints.maxHeight) return size;
    }
    return 9;
  }
}

class _DeveloperConnectionsPainter extends CustomPainter {
  const _DeveloperConnectionsPainter({required this.notes, required this.connections});

  final List<DeveloperNote> notes;
  final List<DeveloperConnection> connections;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.88)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arrowPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    for (final connection in connections) {
      final fromMatches = notes.where((note) => note.id == connection.fromNoteId);
      final toMatches = notes.where((note) => note.id == connection.toNoteId);
      if (fromMatches.isEmpty || toMatches.isEmpty) continue;
      final segment = _connectionSegment(fromMatches.first, toMatches.first);
      canvas.drawLine(segment.start, segment.end, linePaint);

      final angle = math.atan2(segment.end.dy - segment.start.dy, segment.end.dx - segment.start.dx);
      const arrowLength = 11.0;
      const arrowHalfWidth = 5.5;
      final tip = segment.end;
      final base = Offset(tip.dx - math.cos(angle) * arrowLength, tip.dy - math.sin(angle) * arrowLength);
      final perpendicular = Offset(-math.sin(angle) * arrowHalfWidth, math.cos(angle) * arrowHalfWidth);
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + perpendicular.dx, base.dy + perpendicular.dy)
        ..lineTo(base.dx - perpendicular.dx, base.dy - perpendicular.dy)
        ..close();
      canvas.drawPath(path, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DeveloperConnectionsPainter oldDelegate) =>
      oldDelegate.notes != notes || oldDelegate.connections != connections;
}

class _ConnectionSegment {
  const _ConnectionSegment(this.start, this.end);

  final Offset start;
  final Offset end;
}

_ConnectionSegment _connectionSegment(DeveloperNote from, DeveloperNote to) {
  const halfWidth = 105.0;
  const halfHeight = 72.5;
  final fromCenter = from.position + const Offset(halfWidth, halfHeight);
  final toCenter = to.position + const Offset(halfWidth, halfHeight);
  final delta = toCenter - fromCenter;
  final distance = delta.distance;
  if (distance == 0) return _ConnectionSegment(fromCenter, toCenter);

  final unit = Offset(delta.dx / distance, delta.dy / distance);
  final sourceDistance = _distanceFromCenterToRectEdge(unit, halfWidth, halfHeight);
  final targetDistance = _distanceFromCenterToRectEdge(Offset(-unit.dx, -unit.dy), halfWidth, halfHeight);
  return _ConnectionSegment(
    fromCenter + unit * sourceDistance,
    toCenter - unit * targetDistance,
  );
}

double _distanceFromCenterToRectEdge(Offset unit, double halfWidth, double halfHeight) {
  final xDistance = unit.dx.abs() < 0.0001 ? double.infinity : halfWidth / unit.dx.abs();
  final yDistance = unit.dy.abs() < 0.0001 ? double.infinity : halfHeight / unit.dy.abs();
  return math.min(xDistance, yDistance);
}

class _TextDialog extends StatelessWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.controller,
    required this.action,
    this.maxLines = 1,
  });

  final String title;
  final String label;
  final TextEditingController controller;
  final String action;
  final int maxLines;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(action)),
        ],
      );
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({required this.category, required this.selected, required this.onTap});

  final DeveloperCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? Colors.white : Colors.black.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black54),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(color: Color(0xFF21170C), fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
}

class _TowerPainter extends CustomPainter {
  const _TowerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.8),
        radius: 1.25,
        colors: [Color(0xFF34302A), Color(0xFF191B1B), Color(0xFF07090A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final lines = Paint()
      ..color = const Color(0x284A463A)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 56) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
