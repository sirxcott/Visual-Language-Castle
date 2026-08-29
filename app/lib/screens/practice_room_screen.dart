import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/language_tables.dart';
import '../models/archived_work.dart';
import '../models/language_card.dart';
import '../services/archive_storage.dart';
import '../widgets/table_browser.dart';
import '../widgets/workspace_card.dart';

class PracticeRoomScreen extends StatefulWidget {
  const PracticeRoomScreen({super.key, this.initialCards, this.initialConnections, this.sourceWork, this.storage});

  final List<WorkspaceCard>? initialCards;
  final List<CardConnection>? initialConnections;
  final ArchivedWork? sourceWork;
  final ArchiveStorage? storage;

  ArchiveStorage get archiveStorage => storage ?? ArchiveStorage.instance;

  @override
  State<PracticeRoomScreen> createState() => _PracticeRoomScreenState();
}

class _PracticeRoomScreenState extends State<PracticeRoomScreen> {
  int _tableIndex = 0;
  final List<WorkspaceCard> _workspaceCards = [];
  final List<CardConnection> _connections = [];
  bool _connectionMode = false;
  String? _connectionStartId;
  late String _initialArchiveSnapshot;
  bool _allowPop = false;
  bool _exitPromptOpen = false;

  bool get _hasUnsavedChanges => widget.sourceWork != null && _initialArchiveSnapshot != _archiveSnapshot();

  @override
  void initState() {
    super.initState();
    if (widget.initialCards != null) _workspaceCards.addAll(widget.initialCards!);
    if (widget.initialConnections != null) _connections.addAll(widget.initialConnections!);
    _initialArchiveSnapshot = _archiveSnapshot();
  }

  String _archiveSnapshot() {
    final sourceWork = widget.sourceWork;
    if (sourceWork == null) return '';
    return widget.archiveStorage.encodeWorks([
      ArchivedWork(
        id: sourceWork.id,
        name: sourceWork.name,
        savedAt: sourceWork.savedAt,
        isCompleted: sourceWork.isCompleted,
        completedAt: sourceWork.completedAt,
        cards: _workspaceCards.map((card) => WorkspaceCard(instanceId: card.instanceId, card: card.card, position: card.position, notes: card.notes)).toList(),
        connections: List<CardConnection>.of(_connections),
      ),
    ]);
  }

  Future<void> _requestExit() async {
    if (_allowPop || _exitPromptOpen) return;
    if (!_hasUnsavedChanges) {
      _allowPop = true;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _exitPromptOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: const Text('Unsaved changes'),
        content: const Text('This archived work has unsaved changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Return to Editing')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard Changes')),
        ],
      ),
    );
    _exitPromptOpen = false;
    if (!mounted || discard != true) return;
    _allowPop = true;
    Navigator.of(context).pop();
  }

  Future<void> _saveToArchive({String? retryName}) async {
    final name = retryName ?? await showDialog<String>(
      context: context,
      builder: (context) => const _ArchiveNameDialog(),
    );
    if (!mounted || name == null || name.isEmpty) return;
    late final List<ArchivedWork> works;
    try {
      works = await widget.archiveStorage.loadWorks();
      works.insert(0, widget.archiveStorage.createCopy(name: name, cards: _workspaceCards, connections: _connections));
      await widget.archiveStorage.saveWorks(works);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Unable to save to Archive'), action: SnackBarAction(label: 'Retry', onPressed: () => _saveToArchive(retryName: name))));
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Archive')));
  }

  Future<void> _updateArchive({bool retry = false}) async {
    final sourceWork = widget.sourceWork;
    if (sourceWork == null) return;
    final confirmed = retry ? true : await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: const Text('Update archive?'),
        content: Text('Overwrite "${sourceWork.name}" with the current Working Wall?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    late final List<ArchivedWork> works;
    try {
      works = await widget.archiveStorage.loadWorks();
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Unable to load Archive for update'), action: SnackBarAction(label: 'Retry', onPressed: () => _updateArchive(retry: true))));
      return;
    }
    final updated = ArchivedWork(
      id: sourceWork.id,
      name: sourceWork.name,
      savedAt: sourceWork.savedAt,
      isCompleted: sourceWork.isCompleted,
      completedAt: sourceWork.completedAt,
      cards: _workspaceCards.map((card) => WorkspaceCard(instanceId: card.instanceId, card: card.card, position: card.position, notes: card.notes)).toList(),
      connections: List<CardConnection>.of(_connections),
    );
    if (!works.any((work) => work.id == sourceWork.id)) return;
    try {
      await widget.archiveStorage.saveWorks(widget.archiveStorage.replaceWork(works, updated));
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Unable to update Archive'), action: SnackBarAction(label: 'Retry', onPressed: () => _updateArchive(retry: true))));
      return;
    }
    if (!mounted) return;
    _initialArchiveSnapshot = _archiveSnapshot();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archive updated')));
  }

  void _changeTable(int amount) {
    setState(() {
      _tableIndex = (_tableIndex + amount) % languageTables.length;
      if (_tableIndex < 0) _tableIndex += languageTables.length;
    });
  }

  void _placeCard(LanguageCard card, Offset localPosition, {bool mobile = false}) {
    final cascade = mobile
        ? Offset((_workspaceCards.length % 2) * 170.0, (_workspaceCards.length ~/ 2) * 100.0)
        : Offset(_workspaceCards.length * 24.0, _workspaceCards.length * 24.0);
    final position = Offset(
      (localPosition.dx - 100 + cascade.dx).clamp(12.0, double.infinity),
      (localPosition.dy - 40 + cascade.dy).clamp(12.0, double.infinity),
    );
    setState(() => _workspaceCards.add(WorkspaceCard(card: card, position: position)));
  }

  void _addCardToWall(LanguageCard card) => _placeCard(card, const Offset(112, 52), mobile: true);

  void _bringCardToFront(WorkspaceCard card) {
    setState(() {
      _workspaceCards.removeWhere((item) => item.instanceId == card.instanceId);
      _workspaceCards.add(card);
    });
  }

  void _cycleOverlap(WorkspaceCard card) {
    final overlapping = _workspaceCards.where((item) => (item.position - card.position).distance < 24).toList();
    if (overlapping.length < 2) return;
    final next = overlapping.firstWhere((item) => item.instanceId != card.instanceId, orElse: () => card);
    _bringCardToFront(next);
  }

  Offset _clampCardPosition(Offset position, BoxConstraints constraints) {
    return Offset(
      position.dx.clamp(12.0, (constraints.maxWidth - 180).clamp(12.0, double.infinity)),
      position.dy.clamp(12.0, (constraints.maxHeight - 88).clamp(12.0, double.infinity)),
    );
  }

  void _clampWorkspaceCards(BoxConstraints constraints) {
    var changed = false;
    for (final card in _workspaceCards) {
      final clamped = _clampCardPosition(card.position, constraints);
      if (clamped != card.position) {
        card.position = clamped;
        changed = true;
      }
    }
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _toggleConnectionMode() {
    setState(() {
      _connectionMode = !_connectionMode;
      _connectionStartId = null;
    });
  }

  void _selectCardForConnection(WorkspaceCard card) {
    if (!_connectionMode) return;
    setState(() {
      if (_connectionStartId == null) {
        _connectionStartId = card.instanceId;
        return;
      }
      if (_connectionStartId == card.instanceId) return;
      final exists = _connections.any((connection) => connection.fromCardId == _connectionStartId && connection.toCardId == card.instanceId);
      if (!exists) _connections.add(CardConnection(fromCardId: _connectionStartId!, toCardId: card.instanceId));
      _connectionStartId = null;
    });
  }

  Future<void> _removeCard(WorkspaceCard workspaceCard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: const Text('Remove card?'),
        content: Text('Remove "${workspaceCard.card.text}" from the Working Wall?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _workspaceCards.removeWhere((card) => card.instanceId == workspaceCard.instanceId);
      _connections.removeWhere((connection) => connection.fromCardId == workspaceCard.instanceId || connection.toCardId == workspaceCard.instanceId);
      if (_connectionStartId == workspaceCard.instanceId) _connectionStartId = null;
    });
  }

  void _removeConnectionAt(Offset point) {
    if (!_connectionMode) return;
    for (var index = _connections.length - 1; index >= 0; index--) {
      final connection = _connections[index];
      final fromMatches = _workspaceCards.where((card) => card.instanceId == connection.fromCardId);
      final toMatches = _workspaceCards.where((card) => card.instanceId == connection.toCardId);
      if (fromMatches.isEmpty || toMatches.isEmpty) continue;
      final start = fromMatches.first.position + const Offset(95, 40);
      final end = toMatches.first.position + const Offset(95, 40);
      if (_distanceToSegment(point, start, end) < 12) {
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
    return (point - Offset(start.dx + delta.dx * t, start.dy + delta.dy * t)).distance;
  }

  Future<void> _editNotes(WorkspaceCard workspaceCard) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _NotesDialog(workspaceCard: workspaceCard),
    );
    if (!mounted || notes == null) return;
    setState(() => workspaceCard.notes = notes);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.keyA) {
      _changeTable(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      _changeTable(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final table = languageTables[_tableIndex];
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D0E),
        body: SafeArea(
          child: Column(
            children: [
              _RoomHeader(onBack: _requestExit, onSave: _saveToArchive, onUpdate: widget.sourceWork == null ? null : _updateArchive, connectionMode: _connectionMode, onToggleConnections: _toggleConnectionMode),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, roomConstraints) {
                    final wall = DragTarget<LanguageCard>(
                        onAcceptWithDetails: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          _placeCard(details.data, box.globalToLocal(details.offset));
                        },
                        builder: (context, candidateData, rejectedData) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              _clampWorkspaceCards(constraints);
                              return Stack(
                              key: const ValueKey('working-wall-stack'),
                              fit: StackFit.expand,
                              children: [
                                const _WorkspaceBackdrop(),
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapUp: (details) => _removeConnectionAt(details.localPosition),
                                    child: CustomPaint(key: const ValueKey('connections-painter'), painter: _ConnectionsPainter(cards: _workspaceCards, connections: _connections)),
                                  ),
                                ),
                                if (_workspaceCards.isEmpty) const _EmptyWorkspaceHint(),
                                if (candidateData.isNotEmpty) const _DropHighlight(),
                                ..._workspaceCards.map(
                                  (workspaceCard) => WorkspaceCardTile(
                                    key: ValueKey(workspaceCard.instanceId),
                                    workspaceCard: workspaceCard,
                                    mobile: roomConstraints.maxWidth < 700,
                                    onPositionChanged: (position) => setState(() => workspaceCard.position = _clampCardPosition(position, constraints)),
                                    onOpenNotes: () => _editNotes(workspaceCard),
                                    onRemove: () => _removeCard(workspaceCard),
                                    connectionMode: _connectionMode,
                                    isConnectionStart: _connectionStartId == workspaceCard.instanceId,
                                    onSelectForConnection: () => _selectCardForConnection(workspaceCard),
                                    onBringToFront: () => _bringCardToFront(workspaceCard),
                                    onCycleOverlap: () => _cycleOverlap(workspaceCard),
                                  ),
                                ),
                              ],
                              );
                            },
                          );
                        },
                      );
                    if (roomConstraints.maxWidth < 700) {
                      final browserHeight = (roomConstraints.maxHeight * 0.30).clamp(220.0, 300.0);
                      return Column(children: [SizedBox(height: browserHeight, width: double.infinity, child: TableBrowser(table: table, tableIndex: _tableIndex, tableCount: languageTables.length, onPrevious: () => _changeTable(-1), onNext: () => _changeTable(1), onAddCard: _addCardToWall)), Expanded(child: wall)]);
                    }
                    return Row(children: [TableBrowser(table: table, tableIndex: _tableIndex, tableCount: languageTables.length, onPrevious: () => _changeTable(-1), onNext: () => _changeTable(1), onAddCard: _addCardToWall), Expanded(child: wall)]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _NotesDialog extends StatefulWidget {
  const _NotesDialog({required this.workspaceCard});

  final WorkspaceCard workspaceCard;

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.workspaceCard.notes);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.workspaceCard.card;
    return AlertDialog(
      backgroundColor: const Color(0xFF242627),
      title: Text(card.text, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REFERENCE NOTE', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(card.referenceNote.isEmpty ? 'No reference note supplied.' : card.referenceNote, style: const TextStyle(color: Color(0xFFAAA294), fontSize: 13, height: 1.35)),
            const SizedBox(height: 18),
            const Text('YOUR NOTES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              style: const TextStyle(color: Color(0xFFF0E6D2)),
              decoration: const InputDecoration(hintText: 'Add a note for this card', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Save note')),
      ],
    );
  }
}

class _ArchiveNameDialog extends StatefulWidget {
  const _ArchiveNameDialog();

  @override
  State<_ArchiveNameDialog> createState() => _ArchiveNameDialogState();
}

class _ArchiveNameDialogState extends State<_ArchiveNameDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _nameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _nameController.text.trim();
    if (value.isEmpty) {
      setState(() => _nameError = true);
    } else {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242627),
      title: const Text('Save to Archive'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Work name',
          hintText: 'Name this wall arrangement',
          errorText: _nameError ? 'A work name is required' : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.onBack, required this.onSave, required this.onUpdate, required this.connectionMode, required this.onToggleConnections});

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback? onUpdate;
  final bool connectionMode;
  final VoidCallback onToggleConnections;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(color: Color(0xFF151819), border: Border(bottom: BorderSide(color: Color(0xFF4A402F))),),
      child: Row(
        children: [
          IconButton(tooltip: 'Return to Gallery Hall', onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRACTICE ROOM', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 2.5)),
                const SizedBox(height: 3),
                Text('The Working Wall', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 20)),
              ],
            ),
          ),
          const Spacer(),
          if (compact)
            IconButton(
              tooltip: connectionMode ? 'Exit Connections' : 'Connections',
              onPressed: onToggleConnections,
              icon: Icon(connectionMode ? Icons.link_off : Icons.account_tree_outlined),
            )
          else
            FilledButton.icon(onPressed: onToggleConnections, icon: Icon(connectionMode ? Icons.link_off : Icons.account_tree_outlined, size: 17), label: Text(connectionMode ? 'Exit Connections' : 'Connections')),
          const SizedBox(width: 10),
          if (compact)
            IconButton(tooltip: 'Save to Archive', onPressed: onSave, icon: const Icon(Icons.archive_outlined))
          else
            FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.archive_outlined, size: 17), label: const Text('Save to Archive')),
          if (onUpdate != null) ...[
            const SizedBox(width: 10),
            if (compact)
              IconButton(tooltip: 'Update Archive', onPressed: onUpdate, icon: const Icon(Icons.save_outlined))
            else
              FilledButton.icon(onPressed: onUpdate, icon: const Icon(Icons.save_outlined, size: 17), label: const Text('Update Archive')),
          ],
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _ConnectionsPainter extends CustomPainter {
  const _ConnectionsPainter({required this.cards, required this.connections});

  final List<WorkspaceCard> cards;
  final List<CardConnection> connections;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC09A52).withValues(alpha: 0.72)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final arrowPaint = Paint()..color = const Color(0xFFE0B96B)..style = PaintingStyle.fill;
    for (final connection in connections) {
      final fromMatches = cards.where((card) => card.instanceId == connection.fromCardId);
      final toMatches = cards.where((card) => card.instanceId == connection.toCardId);
      if (fromMatches.isEmpty || toMatches.isEmpty) continue;
      final start = fromMatches.first.position + const Offset(95, 40);
      final end = toMatches.first.position + const Offset(95, 40);
      canvas.drawLine(start, end, paint);
      final direction = end - start;
      final length = direction.distance;
      if (length == 0) continue;
      final unit = direction / length;
      final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final tip = midpoint + unit * 7;
      final base = midpoint - unit * 7;
      final normal = Offset(-unit.dy, unit.dx) * 5;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((base + normal).dx, (base + normal).dy)
          ..lineTo((base - normal).dx, (base - normal).dy)
          ..close(),
        arrowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionsPainter oldDelegate) => true;
}

class _WorkspaceBackdrop extends StatelessWidget {
  const _WorkspaceBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF262A2A), Color(0xFF151818), Color(0xFF0C0E0F)]),
      ),
      child: CustomPaint(painter: _WallGridPainter()),
    );
  }
}

class _WallGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x12000000)..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyWorkspaceHint extends StatelessWidget {
  const _EmptyWorkspaceHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 44, color: Color(0xFF655F53)),
            SizedBox(height: 14),
            Text('Your working wall', style: TextStyle(color: Color(0xFFC7BDAA), fontSize: 19)),
            SizedBox(height: 6),
            Text('Drag language cards here to begin building.', style: TextStyle(color: Color(0xFF80796C), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DropHighlight extends StatelessWidget {
  const _DropHighlight();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC09A52).withValues(alpha: 0.6), width: 2)),
      ),
    );
  }
}
