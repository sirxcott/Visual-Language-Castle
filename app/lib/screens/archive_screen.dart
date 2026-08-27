import 'package:flutter/material.dart';

import '../models/archived_work.dart';
import '../services/archive_storage.dart';
import 'practice_room_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<ArchivedWork> _works = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    final works = await ArchiveStorage.instance.loadWorks();
    if (!mounted) return;
    setState(() {
      _works = works;
      _isLoading = false;
    });
  }

  Future<void> _openWork(ArchivedWork work) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticeRoomScreen(initialCards: work.cards, initialConnections: work.connections)));
    _loadWorks();
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
    await ArchiveStorage.instance.saveWorks(_works);
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
    await ArchiveStorage.instance.saveWorks(_works);
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(work.name, style: const TextStyle(color: Color(0xFFE0D3B8), fontSize: 17)), const SizedBox(height: 5), Text('${_savedDate(work.savedAt)}  ·  ${work.cards.length} cards', style: const TextStyle(color: Color(0xFF80796C), fontSize: 12))])),
              IconButton(tooltip: 'Open ${work.name}', onPressed: () => _openWork(work), icon: const Icon(Icons.open_in_new_rounded)),
              IconButton(tooltip: 'Rename ${work.name}', onPressed: () => _renameWork(work), icon: const Icon(Icons.edit_outlined)),
              IconButton(tooltip: 'Delete ${work.name}', onPressed: () => _deleteWork(work), icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC4776E))),
            ],
          ),
        );
      },
    );
  }
}
