import 'package:flutter/material.dart';

import '../models/language_table.dart';
import 'language_card_tile.dart';

class TableBrowser extends StatelessWidget {
  const TableBrowser({
    super.key,
    required this.table,
    required this.tableIndex,
    required this.tableCount,
    required this.onPrevious,
    required this.onNext,
  });

  final LanguageTable table;
  final int tableIndex;
  final int tableCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Color(0xFF121516),
        border: Border(right: BorderSide(color: Color(0xFF4A402F))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
            child: Row(
              children: [
                const Text('TABLE BROWSER', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 2)),
                const Spacer(),
                Text('${tableIndex + 1} / $tableCount', style: const TextStyle(color: Color(0xFF827967), fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(tooltip: 'Previous table (A)', onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                  child: Text(table.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                IconButton(tooltip: 'Next table (D)', onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ),
          if (_tableGuidance.containsKey(table.name))
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(tooltip: 'Open table guidance', onPressed: () => _showTableGuidance(context), icon: const Icon(Icons.info_outline_rounded, size: 18)),
              ),
            ),
          const Divider(color: Color(0xFF342F27), height: 20),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              itemCount: table.cards.length,
              separatorBuilder: (_, index) => const SizedBox(height: 9),
              itemBuilder: (context, index) => LanguageCardTile(card: table.cards[index]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Text('Drag a card onto the wall.\nA / D changes tables quickly.', style: TextStyle(color: Color(0xFF80796C), fontSize: 11, height: 1.45)),
          ),
        ],
      ),
    );
  }

  void _showTableGuidance(BuildContext context) {
    final guidance = _tableGuidance[table.name];
    if (guidance == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: Text(table.name, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: guidance,
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

static const _tableGuidance = <String, List<Widget>>{
  'Nominals': [
    Text('Nominals are the abbreviated app term for hypnotic nominalizations.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
  'Linkages': [
    Text('Linkages are spoken transition structures that maintain and shape hypnotic/conversational momentum.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
    SizedBox(height: 16),
    Text('RESTATEMENT LINKAGES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
    SizedBox(height: 5),
    Text('Linkages used to restate or reinforce a suggestion in a different way.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
    SizedBox(height: 14),
    Text('MOMENTUM LINKAGES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
    SizedBox(height: 5),
    Text('Linkages used to maintain verbal flow and give the speaker processing time without breaking delivery.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
};
}
