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
    work.isCompleted = completing;
    work.completedAt = completing ? DateTime.now() : null;
    try {
      await _storage.saveWorks(_works);
    } on Object {
      _showStorageError('Unable to update Archive');
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _renameWork(ArchivedWork work) async {
    final controller = TextEditingController(text: work.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: const Text('Rename archived work'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Work name'), onSubmitted: (value) => Navigator.pop(context, value.trim())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Rename')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    work.name = name;
    try {
      await _storage.saveWorks(_works);
    } on Object {
      _showStorageError('Unable to rename archived work');
      return;
    }
    if (mounted) setState(() {});
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
    _works.removeWhere((item) => item.id == work.id);
    try {
      await _storage.saveWorks(_works);
    } on Object {
      _showStorageError('Unable to delete archived work');
      return;
    }
    if (mounted) setState(() {});
  }

  String _savedDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}  ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B1D1E), Color(0xFF0A0B0C)])),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(tooltip: 'Return to Gallery Hall', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                        const SizedBox(width: 8),
                        const Text('ARCHIVE', style: TextStyle(color: Color(0xFFC09A52), fontSize: 12, letterSpacing: 3.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Archive', style: TextStyle(color: Color(0xFFF1E7D0), fontSize: 38)),
                    const SizedBox(height: 8),
                    const Text('Saved arrangements from the working wall.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 16)),
                    const SizedBox(height: 30),
                    Expanded(child: _buildWorks()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorks() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFC09A52)));
    if (_works.isEmpty) {
      return const Center(child: Text('No archived works yet.', style: TextStyle(color: Color(0xFF80796C), fontSize: 16)));
    }
    return ListView.separated(
      itemCount: _works.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final work = _works[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF151718), border: Border.all(color: const Color(0xFF645238))),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_mosaic_outlined, color: Color(0xFFC09A52), size: 28),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Flexible(child: Text(work.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE0D3B8), fontSize: 17))), if (work.isCompleted) ...[const SizedBox(width: 10), const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF5D9A78)), const SizedBox(width: 5), const Text('Completed', style: TextStyle(color: Color(0xFF5D9A78), fontSize: 11))]]),
                const SizedBox(height: 5),
                Text('${_savedDate(work.savedAt)}  ·  ${work.cards.length} cards', style: const TextStyle(color: Color(0xFF80796C), fontSize: 12)),
              ])),
              IconButton(tooltip: 'Open ${work.name}', onPressed: () => _openWork(work), icon: const Icon(Icons.open_in_new_rounded)),
              IconButton(tooltip: work.isCompleted ? 'Return "${work.name}" to Archive' : 'Mark "${work.name}" complete', onPressed: () => _changeCompletion(work), icon: Icon(work.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline, color: work.isCompleted ? const Color(0xFFC09A52) : const Color(0xFF5D9A78))),
              IconButton(tooltip: 'Rename ${work.name}', onPressed: () => _renameWork(work), icon: const Icon(Icons.edit_outlined)),
              IconButton(tooltip: 'Delete ${work.name}', onPressed: () => _deleteWork(work), icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC4776E))),
            ],
          ),
        );
      },
    );
  }
}
