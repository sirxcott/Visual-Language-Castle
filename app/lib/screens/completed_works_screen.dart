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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B1D1E), Color(0xFF0A0B0C)])),
        child: SafeArea(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [IconButton(tooltip: 'Return to Gallery Hall', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)), const SizedBox(width: 8), const Text('COMPLETED WORKS', style: TextStyle(color: Color(0xFFC09A52), fontSize: 12, letterSpacing: 3.5))]),
                      const SizedBox(height: 10),
                      const Text('Completed Works', style: TextStyle(color: Color(0xFFF1E7D0), fontSize: 38)),
                      const SizedBox(height: 8),
                      const Text('Finished arrangements from your archive.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 16)),
                      const SizedBox(height: 30),
                      _buildWorks(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorks() {
    if (_isLoading) return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator(color: Color(0xFFC09A52))));
    if (_works.isEmpty) return const SizedBox(height: 260, child: Center(child: Text('No completed works yet.', style: TextStyle(color: Color(0xFF80796C), fontSize: 16))));
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

class _CompletedWorkItem extends StatelessWidget {
  const _CompletedWorkItem({required this.work, required this.completionDate, required this.onOpen});

  final ArchivedWork work;
  final String completionDate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF151718), border: Border.all(color: const Color(0xFF645238))),
      child: Row(
        children: [
          const Icon(Icons.collections_bookmark_outlined, color: Color(0xFFC09A52), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(work.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE0D3B8), fontSize: 17)),
                const SizedBox(height: 5),
                Text('$completionDate  ·  ${work.cards.length} cards  ·  ${work.connections.length} ${work.connections.length == 1 ? 'connection' : 'connections'}', style: const TextStyle(color: Color(0xFF80796C), fontSize: 12)),
              ],
            ),
          ),
          IconButton(tooltip: 'Open ${work.name}', onPressed: onOpen, icon: const Icon(Icons.open_in_new_rounded)),
        ],
      ),
    );
  }
}
