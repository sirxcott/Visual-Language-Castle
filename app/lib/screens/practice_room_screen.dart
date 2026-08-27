import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/language_tables.dart';
import '../models/archived_work.dart';
import '../models/language_card.dart';
import '../services/archive_storage.dart';
import '../widgets/table_browser.dart';
import '../widgets/workspace_card.dart';

class PracticeRoomScreen extends StatefulWidget {
  const PracticeRoomScreen({super.key, this.initialCards, this.initialConnections});

  final List<WorkspaceCard>? initialCards;
  final List<CardConnection>? initialConnections;

  @override
  State<PracticeRoomScreen> createState() => _PracticeRoomScreenState();
}

class _PracticeRoomScreenState extends State<PracticeRoomScreen> {
  int _tableIndex = 0;
  final List<WorkspaceCard> _workspaceCards = [];
  final List<CardConnection> _connections = [];
  bool _connectionMode = false;
  String? _connectionStartId;

  @override
  void initState() {
    super.initState();
    if (widget.initialCards != null) _workspaceCards.addAll(widget.initialCards!);
    if (widget.initialConnections != null) _connections.addAll(widget.initialConnections!);
  }

  Future<void> _saveToArchive() async {
    final nameController = TextEditingController();
    var nameError = false;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF242627),
          title: const Text('Save to Archive'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Work name',
              hintText: 'Name this wall arrangement',
              errorText: nameError ? 'A work name is required' : null,
            ),
            onSubmitted: (value) {
              if (value.trim().isEmpty) {
                setDialogState(() => nameError = true);
              } else {
                Navigator.pop(context, value.trim());
              }
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = nameController.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => nameError = true);
                } else {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    final works = await ArchiveStorage.instance.loadWorks();
    works.insert(
      0,
      ArchivedWork(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        savedAt: DateTime.now(),
        cards: _workspaceCards.map((card) => WorkspaceCard(card: card.card, position: card.position, notes: card.notes)).toList(),
        connections: List<CardConnection>.of(_connections),
      ),
    );
    await ArchiveStorage.instance.saveWorks(works);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Archive')));
  }

  void _changeTable(int amount) {
    setState(() {
      _tableIndex = (_tableIndex + amount) % languageTables.length;
      if (_tableIndex < 0) _tableIndex += languageTables.length;
    });
  }

  void _placeCard(LanguageCard card, Offset localPosition) {
    final position = Offset(
      (localPosition.dx - 100).clamp(12.0, double.infinity),
      (localPosition.dy - 40).clamp(12.0, double.infinity),
    );
    setState(() => _workspaceCards.add(WorkspaceCard(card: card, position: position)));
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
        _connectionStartId = card.card.id;
        return;
      }
      if (_connectionStartId == card.card.id) return;
      final exists = _connections.any((connection) => connection.fromCardId == _connectionStartId && connection.toCardId == card.card.id);
      if (!exists) _connections.add(CardConnection(fromCardId: _connectionStartId!, toCardId: card.card.id));
      _connectionStartId = null;
    });
  }

  void _removeConnectionAt(Offset point) {
    if (!_connectionMode) return;
    for (var index = _connections.length - 1; index >= 0; index--) {
      final connection = _connections[index];
      final fromMatches = _workspaceCards.where((card) => card.card.id == connection.fromCardId);
      final toMatches = _workspaceCards.where((card) => card.card.id == connection.toCardId);
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
    final controller = TextEditingController(text: workspaceCard.notes);
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: Text(workspaceCard.card.text, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 18)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REFERENCE NOTE', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(workspaceCard.card.referenceNote.isEmpty ? 'No reference note supplied.' : workspaceCard.card.referenceNote, style: const TextStyle(color: Color(0xFFAAA294), fontSize: 13, height: 1.35)),
              const SizedBox(height: 18),
              const Text('YOUR NOTES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
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
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save note')),
        ],
      ),
    );
    controller.dispose();
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
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D0E),
        body: SafeArea(
          child: Column(
            children: [
              _RoomHeader(onBack: () => Navigator.of(context).pop(), onSave: _saveToArchive, connectionMode: _connectionMode, onToggleConnections: _toggleConnectionMode),
              Expanded(
                child: Row(
                  children: [
                    TableBrowser(
                      table: table,
                      tableIndex: _tableIndex,
                      tableCount: languageTables.length,
                      onPrevious: () => _changeTable(-1),
                      onNext: () => _changeTable(1),
                    ),
                    Expanded(
                      child: DragTarget<LanguageCard>(
                        onAcceptWithDetails: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          _placeCard(details.data, box.globalToLocal(details.offset));
                        },
                        builder: (context, candidateData, rejectedData) {
                          return LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              fit: StackFit.expand,
                              children: [
                                const _WorkspaceBackdrop(),
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapUp: (details) => _removeConnectionAt(details.localPosition),
                                    child: CustomPaint(painter: _ConnectionsPainter(cards: _workspaceCards, connections: _connections)),
                                  ),
                                ),
                                if (_workspaceCards.isEmpty) const _EmptyWorkspaceHint(),
                                if (candidateData.isNotEmpty) const _DropHighlight(),
                                ..._workspaceCards.map(
                                  (workspaceCard) => WorkspaceCardTile(
                                    key: ValueKey(workspaceCard.card.id),
                                    workspaceCard: workspaceCard,
                                    onPositionChanged: (position) => setState(() => workspaceCard.position = position),
                                    onOpenNotes: () => _editNotes(workspaceCard),
                                    connectionMode: _connectionMode,
                                    isConnectionStart: _connectionStartId == workspaceCard.card.id,
                                    onSelectForConnection: () => _selectCardForConnection(workspaceCard),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.onBack, required this.onSave, required this.connectionMode, required this.onToggleConnections});

  final VoidCallback onBack;
  final VoidCallback onSave;
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
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRACTICE ROOM', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 2.5)),
              SizedBox(height: 3),
              Text('The Working Wall', style: TextStyle(color: Color(0xFFF0E6D2), fontSize: 20)),
            ],
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
    final arrowPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    for (final connection in connections) {
      final fromMatches = cards.where((card) => card.card.id == connection.fromCardId);
      final toMatches = cards.where((card) => card.card.id == connection.toCardId);
      if (fromMatches.isEmpty || toMatches.isEmpty) continue;
      final start = fromMatches.first.position + const Offset(95, 40);
      final end = toMatches.first.position + const Offset(95, 40);
      canvas.drawLine(start, end, paint);
      final direction = end - start;
      final length = direction.distance;
      if (length == 0) continue;
      final unit = direction / length;
      final tip = end - unit * 92;
      final base = tip - unit * 12;
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
