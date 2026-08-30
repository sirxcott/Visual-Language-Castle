import 'package:flutter/material.dart';

import '../models/language_card.dart';
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
    this.onAddCard,
  });

  final LanguageTable table;
  final int tableIndex;
  final int tableCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<LanguageCard>? onAddCard;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final wallCards = table.cards.where((card) => !card.isResearchOnly).toList();
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
            padding: EdgeInsets.fromLTRB(16, mobile ? 10 : 18, 12, mobile ? 6 : 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('TABLE BROWSER', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.8)),
                ),
                const SizedBox(width: 8),
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
          Divider(color: const Color(0xFF342F27), height: mobile ? 10 : 20),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(14, 0, 14, mobile ? 10 : 20),
              itemCount: wallCards.length,
              separatorBuilder: (_, index) => const SizedBox(height: 9),
              itemBuilder: (context, index) => LanguageCardTile(card: wallCards[index], onAddToWall: onAddCard == null ? null : () => onAddCard!(wallCards[index])),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, mobile ? 8 : 18),
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
  'Verbs': [
    Text('Verbs are single root process words naming fundamental internal actions or processes. Longer functional phrases belong in specialized Tables.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
  'TRANCE WORDPLAY': [
    Text('Trance Wordplay uses phonetic puns, homophones, and prefix substitutions (such as "Trance-" for "trans-") to create double meanings and unconscious associations.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
  'Compliance Commands': [
    Text('These are individual low-effort commands used to obtain or maintain easy compliance and hypnotic momentum. They may later be classified as Voluntary or Involuntary Compliance. A single command is NOT a Compliance Set.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
  'Compliance Sets': [
    Text('A Compliance Set is three or more Compliance Commands given one after another. Fewer than three commands does not constitute a set. The sequence should flow naturally as a unit. This table is intentionally empty until approved sets are added.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
  'Linkages': [
    Text('Linkages are spoken transition structures that maintain and shape hypnotic/conversational momentum.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
    SizedBox(height: 16),
    Text('BASIC LINKAGES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
    SizedBox(height: 5),
    Text('Simple connective scaffolding joining statements.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
    SizedBox(height: 14),
    Text('RESTATEMENT LINKAGES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
    SizedBox(height: 5),
    Text('Structures used to restate or rephrase an idea while maintaining flow.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
    SizedBox(height: 14),
    Text('MOMENTUM LINKAGES', style: TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)),
    SizedBox(height: 5),
    Text('Structures used to maintain or propel conversational/hypnotic momentum.', style: TextStyle(color: Color(0xFFE0D3B8), fontSize: 14, height: 1.4)),
  ],
};
}
