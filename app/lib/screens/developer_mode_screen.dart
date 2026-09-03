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
  String _boardName = 'Untitled Development';
  String _boardId = '';
  DateTime _savedAt = DateTime.now();
  List<DeveloperBoard> _savedBoards = [];
  bool _loading = true;
  BoxConstraints? _workSurface;

  DeveloperBoardStorage get _storage => widget.storage ?? DeveloperBoardStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    final boards = await _storage.loadBoards();
    if (mounted) setState(() { _savedBoards = boards; _loading = false; });
  }

  void _addNote() {
    final index = _notes.length;
    setState(() => _notes.add(DeveloperNote(
          id: 'developer-${DateTime.now().microsecondsSinceEpoch}-$index',
          text: '',
          researchNotes: '',
          colorValue: DeveloperCategory.values[index % (DeveloperCategory.values.length - 1)].color.toARGB32(),
          category: DeveloperCategory.values[index % (DeveloperCategory.values.length - 1)],
          position: Offset(32.0 + (index % 4) * 42, 36.0 + (index % 5) * 34),
        )));
  }

  void _deleteNote(DeveloperNote note) => setState(() => _notes.removeWhere((item) => item.id == note.id));

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

  Future<void> _editResearch(DeveloperNote note) async {
    final controller = TextEditingController(text: note.researchNotes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(title: 'Notes / Research', label: 'Secondary notes', controller: controller, action: 'Save notes', maxLines: 8),
    );
    controller.dispose();
    if (result != null) setState(() => note.researchNotes = result);
  }

  Future<void> _chooseColor(DeveloperNote note) async {
    final selected = await showDialog<DeveloperCategory>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sticky category'),
        content: SizedBox(width: 420, child: Wrap(spacing: 10, runSpacing: 10, children: [for (final category in DeveloperCategory.values.where((category) => category != DeveloperCategory.unknown)) _CategoryChoice(category: category, selected: category == note.category, onTap: () => Navigator.pop(context, category))])),
      ),
    );
    if (selected != null) setState(() => note.category = selected);
  }

  Future<void> _saveBoard() async {
    final controller = TextEditingController(text: _boardName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextDialog(title: 'Save Developer Board', label: 'Board name', controller: controller, action: 'Save board'),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final now = DateTime.now();
    final board = DeveloperBoard(id: _boardId.isEmpty ? now.microsecondsSinceEpoch.toString() : _boardId, name: name, savedAt: now, notes: _notes.map((note) => note.copy()).toList());
    final boards = List<DeveloperBoard>.of(_savedBoards);
    final existing = boards.indexWhere((item) => item.id == board.id);
    if (existing >= 0) { boards[existing] = board; } else { boards.insert(0, board); }
    await _storage.saveBoards(boards);
    if (mounted) setState(() { _boardId = board.id; _boardName = board.name; _savedAt = board.savedAt; _savedBoards = boards; });
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
              : ListView.separated(shrinkWrap: true, itemCount: _savedBoards.length, separatorBuilder: (_, _) => const Divider(), itemBuilder: (context, index) {
                  final item = _savedBoards[index];
                  return ListTile(title: Text(item.name), subtitle: Text('${item.notes.length} notes'), onTap: () => Navigator.pop(context, item));
                }),
        ),
      ),
    );
    if (board != null) setState(() { _boardId = board.id; _boardName = board.name; _savedAt = board.savedAt; _notes..clear()..addAll(board.notes.map((note) => note.copy())); });
  }

  void _exportBoard() {
    final board = DeveloperBoard(id: _boardId, name: _boardName, savedAt: _savedAt, notes: _notes.map((note) => note.copy()).toList());
    showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Export Board'), content: SizedBox(width: 560, child: SelectableText(_storage.exportBoard(board))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        const CustomPaint(painter: _TowerPainter()),
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            _DeveloperToolbar(boardName: _boardName, onBack: () => Navigator.pop(context), onAdd: _addNote, onSave: _saveBoard, onOpen: _openBoard, onExport: _exportBoard),
            const SizedBox(height: 14),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              _workSurface = constraints;
              return Container(
                key: const ValueKey('developer-work-surface'),
                decoration: BoxDecoration(color: const Color(0xDD16191A), border: Border.all(color: const Color(0xFF80643A), width: 1.5), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 22)]),
                child: Stack(children: [
                  const Positioned(left: 20, top: 18, child: Text('THE ALCHEMIST\'S WORKBENCH', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700))),
                  if (!_loading && _notes.isEmpty) const Center(child: Text('Create a note to begin developing a structure.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 16))),
                  ..._notes.map((note) => _DeveloperStickyNote(note: note, onChanged: () => setState(() {}), onMove: (delta) => _moveNote(note, delta), onDelete: () => _deleteNote(note), onResearch: () => _editResearch(note), onColor: () => _chooseColor(note))),
                ]),
              );
            })),
          ]),
        )),
      ]),
    );
  }
}

class _DeveloperToolbar extends StatelessWidget {
  const _DeveloperToolbar({required this.boardName, required this.onBack, required this.onAdd, required this.onSave, required this.onOpen, required this.onExport});
  final String boardName;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onExport;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        IconButton(tooltip: 'Return to Gallery Hall', onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37))),
        Text('DEVELOPER MODE  |  $boardName', style: const TextStyle(color: Color(0xFFF5EEDA), fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('New Sticky')),
        OutlinedButton.icon(onPressed: onSave, icon: const Icon(Icons.save_outlined), label: const Text('Save Board')),
        OutlinedButton.icon(onPressed: onOpen, icon: const Icon(Icons.folder_open_outlined), label: const Text('Open Board')),
        OutlinedButton.icon(onPressed: onExport, icon: const Icon(Icons.ios_share_outlined), label: const Text('Export Board')),
      ]);
}

class _DeveloperStickyNote extends StatefulWidget {
  const _DeveloperStickyNote({required this.note, required this.onChanged, required this.onMove, required this.onDelete, required this.onResearch, required this.onColor});
  final DeveloperNote note;
  final VoidCallback onChanged;
  final ValueChanged<Offset> onMove;
  final VoidCallback onDelete;
  final VoidCallback onResearch;
  final VoidCallback onColor;
  @override
  State<_DeveloperStickyNote> createState() => _DeveloperStickyNoteState();
}

class _DeveloperStickyNoteState extends State<_DeveloperStickyNote> {
  late final TextEditingController _controller = TextEditingController(text: widget.note.text);
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = widget.note.color;
    return Positioned(left: widget.note.position.dx, top: widget.note.position.dy, child: SizedBox(
      width: 210, height: 145,
      child: Material(color: Colors.transparent, child: Container(
        key: ValueKey('developer-note-${widget.note.id}'),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withValues(alpha: 0.35)), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(2, 5))]),
        child: Column(children: [
          GestureDetector(onPanUpdate: (details) => widget.onMove(details.delta), child: Container(height: 27, color: Colors.black.withValues(alpha: 0.18), child: Row(children: [
            const SizedBox(width: 7), const Icon(Icons.drag_indicator_rounded, size: 17, color: Color(0xDD21170C)), const SizedBox(width: 4), Expanded(child: Text(widget.note.category.label.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF21170C), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
            IconButton(tooltip: 'Note color', onPressed: widget.onColor, icon: const Icon(Icons.palette_outlined, size: 17), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 28, height: 28)),
            IconButton(tooltip: 'Notes / Research', onPressed: widget.onResearch, icon: const Icon(Icons.menu_book_outlined, size: 17), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 28, height: 28)),
            IconButton(tooltip: 'Delete sticky', onPressed: widget.onDelete, icon: const Icon(Icons.close, size: 17), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 28, height: 28)),
          ]))),
          Expanded(child: Padding(padding: const EdgeInsets.all(10), child: LayoutBuilder(builder: (context, constraints) => TextField(
            key: ValueKey('developer-note-text-${widget.note.id}'), controller: _controller, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
            onChanged: (value) { widget.note.text = value; widget.onChanged(); },
            style: TextStyle(color: const Color(0xFF21170C), fontWeight: FontWeight.w600, fontSize: _fitFont(_controller.text, constraints)),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Type a language structure...', hintStyle: TextStyle(color: Color(0x8821170C))),
          )))),
        ]),
      )),
    ));
  }
  double _fitFont(String text, BoxConstraints constraints) {
    for (var size = 17.0; size >= 9; size -= 1) {
      final painter = TextPainter(text: TextSpan(text: text.isEmpty ? 'Type a language structure...' : text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w600)), maxLines: null, textDirection: TextDirection.ltr)..layout(maxWidth: constraints.maxWidth);
      if (painter.height <= constraints.maxHeight) return size;
    }
    return 9;
  }
}

class _TextDialog extends StatelessWidget {
  const _TextDialog({required this.title, required this.label, required this.controller, required this.action, this.maxLines = 1});
  final String title; final String label; final TextEditingController controller; final String action; final int maxLines;
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(title), content: TextField(controller: controller, autofocus: true, maxLines: maxLines, decoration: InputDecoration(labelText: label)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(action))]);
}

class _CategoryChoice extends StatelessWidget { const _CategoryChoice({required this.category, required this.selected, required this.onTap}); final DeveloperCategory category; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(width: 190, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(4), border: Border.all(color: selected ? Colors.white : Colors.black.withValues(alpha: 0.25), width: selected ? 2 : 1)), child: Row(children: [Container(width: 16, height: 16, decoration: BoxDecoration(color: category.color, shape: BoxShape.circle, border: Border.all(color: Colors.black54))), const SizedBox(width: 8), Expanded(child: Text(category.label, style: const TextStyle(color: Color(0xFF21170C), fontWeight: FontWeight.w800)))]))); }

class _TowerPainter extends CustomPainter { const _TowerPainter(); @override void paint(Canvas canvas, Size size) { final paint = Paint()..shader = const RadialGradient(center: Alignment(0, -0.8), radius: 1.25, colors: [Color(0xFF34302A), Color(0xFF191B1B), Color(0xFF07090A)]).createShader(Offset.zero & size); canvas.drawRect(Offset.zero & size, paint); final lines = Paint()..color = const Color(0x284A463A)..strokeWidth = 1; for (var y = 0.0; y < size.height; y += 56) { canvas.drawLine(Offset(0, y), Offset(size.width, y), lines); } } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }