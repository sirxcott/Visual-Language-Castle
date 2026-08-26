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
}
