import 'package:flutter/material.dart';

import '../data/language_tables.dart';
import '../data/language_taxonomy.dart';
import '../models/language_card.dart';

class ResearchLaboratoryScreen extends StatefulWidget {
  const ResearchLaboratoryScreen({super.key});

  @override
  State<ResearchLaboratoryScreen> createState() => _ResearchLaboratoryScreenState();
}

class _ResearchLaboratoryScreenState extends State<ResearchLaboratoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedTable = 'All Tables';
  String _selectedCategory = 'All Categories';
  String _selectedLinkageSubtype = 'All Linkage Subtypes';

  List<LanguageCard> get _allCards => [for (final table in languageTables) ...table.cards];

  List<LanguageCard> get _filteredCards {
    final query = _searchController.text.trim().toLowerCase();
    return _allCards.where((card) {
      final matchesTable = _selectedTable == 'All Tables' || card.tableName == _selectedTable;
      final matchesCategory = _selectedCategory == 'All Categories' || card.category.label == _selectedCategory;
      final matchesSubtype = _selectedLinkageSubtype == 'All Linkage Subtypes' || (card.tableName == 'Linkages' && linkageSubtypeLabel(card) == _selectedLinkageSubtype);
      final matchesSearch = query.isEmpty || card.text.toLowerCase().contains(query) || card.tableName.toLowerCase().contains(query);
      return matchesTable && matchesCategory && matchesSubtype && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateResults);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_updateResults)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateResults() => setState(() {});

  void _changeTable(String table) {
    setState(() {
      _selectedTable = table;
      if (table != 'All Tables' && table != 'Linkages') _selectedLinkageSubtype = 'All Linkage Subtypes';
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedTable = 'All Tables';
      _selectedCategory = 'All Categories';
      _selectedLinkageSubtype = 'All Linkage Subtypes';
    });
    _searchFocusNode.requestFocus();
  }

  void _showDetails(LanguageCard card) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242627),
        title: Text(card.text, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailLabel(label: 'TABLE', value: card.tableName),
            const SizedBox(height: 16),
            _DetailLabel(label: 'CATEGORY', value: card.category.label, color: card.category.color),
            if (card.tableName == 'Linkages') ...[
              const SizedBox(height: 16),
              _DetailLabel(label: 'LINKAGE STATUS', value: linkageSubtypeLabel(card), color: const Color(0xFFC09A52)),
            ],
            const SizedBox(height: 16),
            _DetailLabel(label: 'REFERENCE NOTE', value: card.referenceNote.isEmpty ? 'No reference note supplied.' : card.referenceNote),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B1D1E), Color(0xFF0A0B0C)]),
        ),
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
                    Row(
                      children: [
                        IconButton(tooltip: 'Return to Gallery Hall', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
                        const SizedBox(width: 8),
                        const Text('RESEARCH', style: TextStyle(color: Color(0xFFC09A52), fontSize: 12, letterSpacing: 3.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Research Laboratory', style: TextStyle(color: Color(0xFFF1E7D0), fontSize: 38)),
                    const SizedBox(height: 8),
                    const Text('Explore the language collection across all tables.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 16)),
                    const SizedBox(height: 28),
                    _ResearchControls(
                      searchController: _searchController,
                      selectedTable: _selectedTable,
                      onTableChanged: _changeTable,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (value) => setState(() => _selectedCategory = value),
                      selectedLinkageSubtype: _selectedLinkageSubtype,
                      onLinkageSubtypeChanged: (value) => setState(() => _selectedLinkageSubtype = value),
                      onReset: _resetFilters,
                      searchFocusNode: _searchFocusNode,
                    ),
                    const SizedBox(height: 20),
                    Text('${_filteredCards.length} results', key: const ValueKey('research-result-count'), style: const TextStyle(color: Color(0xFF80796C), fontSize: 12)),
                    const SizedBox(height: 10),
                    _buildResults(),
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

  Widget _buildResults() {
    final cards = _filteredCards;
    if (cards.isEmpty) {
      return const Center(
        child: Text('No language cards match your search.', style: TextStyle(color: Color(0xFFAAA294), fontSize: 16)),
      );
    }
    return GridView.builder(
      key: const ValueKey('research-results'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisExtent: 160, crossAxisSpacing: 14, mainAxisSpacing: 14),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _ResearchResultCard(card: card, onTap: () => _showDetails(card));
      },
    );
  }
}

class _ResearchControls extends StatelessWidget {
  const _ResearchControls({required this.searchController, required this.selectedTable, required this.onTableChanged, required this.selectedCategory, required this.onCategoryChanged, required this.selectedLinkageSubtype, required this.onLinkageSubtypeChanged, required this.onReset, required this.searchFocusNode});

  final TextEditingController searchController;
  final String selectedTable;
  final ValueChanged<String> onTableChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String selectedLinkageSubtype;
  final ValueChanged<String> onLinkageSubtypeChanged;
  final VoidCallback onReset;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = Semantics(
          textField: true,
          label: 'Search language cards',
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            key: const ValueKey('research-search-field'),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Search language cards',
              hintText: 'Search by card text or table',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        );
        final filter = DropdownButtonFormField<String>(
          initialValue: selectedTable,
          isExpanded: true,
          key: const ValueKey('research-table-filter'),
          decoration: const InputDecoration(labelText: 'Table', border: OutlineInputBorder()),
          items: ['All Tables', ...languageTables.map((table) => table.name)].map((table) => DropdownMenuItem(value: table, child: Text(table, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) {
            if (value != null) onTableChanged(value);
          },
        );
        final categoryFilter = DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          isExpanded: true,
          key: const ValueKey('research-category-filter'),
          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          items: [
            'All Categories',
            ...CardCategory.values.map((category) => category.label),
          ].map((category) => DropdownMenuItem(value: category, child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) {
            if (value != null) onCategoryChanged(value);
          },
        );
        final linkageSubtypeFilter = DropdownButtonFormField<String>(
          initialValue: selectedLinkageSubtype,
          isExpanded: true,
          key: const ValueKey('research-linkage-subtype-filter'),
          decoration: const InputDecoration(labelText: 'Linkage Subtype', border: OutlineInputBorder()),
          items: ['All Linkage Subtypes', 'Restatement Linkages', 'Momentum Linkages', 'Unclassified']
              .map((subtype) => DropdownMenuItem(value: subtype, child: Text(subtype, maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (value) {
            if (value != null) onLinkageSubtypeChanged(value);
          },
        );
        final showLinkageSubtype = selectedTable == 'All Tables' || selectedTable == 'Linkages';
        final reset = Semantics(
          button: true,
          label: 'Reset research filters',
          child: TextButton.icon(onPressed: onReset, icon: const Icon(Icons.refresh_rounded, size: 17), label: const Text('Reset Filters')),
        );
        if (constraints.maxWidth < 1100) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [search, const SizedBox(height: 12), filter, const SizedBox(height: 12), categoryFilter, if (showLinkageSubtype) ...[const SizedBox(height: 12), linkageSubtypeFilter], const SizedBox(height: 8), reset]);
        }
        return Column(
          children: [
            Row(children: [Expanded(child: search), const SizedBox(width: 14), SizedBox(width: 220, child: filter), const SizedBox(width: 14), SizedBox(width: 220, child: categoryFilter)]),
            if (showLinkageSubtype) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: SizedBox(width: 220, child: linkageSubtypeFilter)),
            ],
            Align(alignment: Alignment.centerLeft, child: reset),
          ],
        );
      },
    );
  }
}

class _ResearchResultCard extends StatelessWidget {
  const _ResearchResultCard({required this.card, required this.onTap});

  final LanguageCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = card.category.color;
    return Semantics(
      button: true,
      label: 'Open research details for ${card.text}',
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
          decoration: BoxDecoration(color: const Color(0xFF151718), border: Border.all(color: color.withValues(alpha: 0.75)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF0E6D2), fontSize: 16, height: 1.25)),
              const Spacer(),
              Text(card.tableName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFA9A294), fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 7), Flexible(child: Text(card.category.label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11))), const SizedBox(width: 8), const Icon(Icons.open_in_new_rounded, size: 15, color: Color(0xFF80796C))]),
              if (card.tableName == 'Linkages') ...[
                const SizedBox(height: 5),
                Text(linkageSubtypeLabel(card), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFC09A52), fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFFC09A52), fontSize: 10, letterSpacing: 1.5)), const SizedBox(height: 5), Text(value, style: TextStyle(color: color ?? const Color(0xFFE0D3B8), fontSize: 14, height: 1.35))]);
  }
}
