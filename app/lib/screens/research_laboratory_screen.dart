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
  final ScrollController _scrollController = ScrollController();
  String _selectedTable = 'All Tables';
  String _selectedCategory = 'All Categories';
  String _selectedLinkageSubtype = 'All Linkage Subtypes';
  String _selectedEmbeddedSubtype = 'All Embedded Subtypes';
  String _selectedComplianceSubtype = 'All Compliance Subtypes';

  List<LanguageCard> get _allCards => [for (final table in languageTables) ...table.cards];

  List<LanguageCard> get _filteredCards {
    final query = _searchController.text.trim().toLowerCase();
    return _allCards.where((card) {
      final matchesTable = _selectedTable == 'All Tables' || card.tableName == _selectedTable;
      final matchesCategory = _selectedCategory == 'All Categories' || card.category.label == _selectedCategory;
      final matchesSubtype = _selectedLinkageSubtype == 'All Linkage Subtypes' || (card.tableName == 'Linkages' && linkageSubtypeLabel(card) == _selectedLinkageSubtype);
      final matchesEmbeddedSubtype = _selectedEmbeddedSubtype == 'All Embedded Subtypes' || ((card.tableName == 'Embedded' || card.category == CardCategory.embedded) && embeddedSubtypeLabel(card) == _selectedEmbeddedSubtype);
      final matchesComplianceSubtype = _selectedComplianceSubtype == 'All Compliance Subtypes' || ((card.tableName == 'Compliance Commands' || card.category == CardCategory.red) && hasComplianceSubtype(card, _selectedComplianceSubtype));
      final matchesSearch = query.isEmpty ||
          card.text.toLowerCase().contains(query) ||
          card.tableName.toLowerCase().contains(query) ||
          card.passage.toLowerCase().contains(query) ||
          card.reconstructedIntent.toLowerCase().contains(query) ||
          card.fragments.any((f) => f.toLowerCase().contains(query));
      return matchesTable && matchesCategory && matchesSubtype && matchesEmbeddedSubtype && matchesComplianceSubtype && matchesSearch;
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
    _scrollController.dispose();
    super.dispose();
  }

  void _updateResults() => setState(() {});

  void _changeTable(String table) {
    setState(() {
      _selectedTable = table;
      if (table != 'All Tables' && table != 'Linkages') _selectedLinkageSubtype = 'All Linkage Subtypes';
      if (table != 'All Tables' && table != 'Embedded') _selectedEmbeddedSubtype = 'All Embedded Subtypes';
      if (table != 'All Tables' && table != 'Compliance Commands') _selectedComplianceSubtype = 'All Compliance Subtypes';
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedTable = 'All Tables';
      _selectedCategory = 'All Categories';
      _selectedLinkageSubtype = 'All Linkage Subtypes';
      _selectedEmbeddedSubtype = 'All Embedded Subtypes';
      _selectedComplianceSubtype = 'All Compliance Subtypes';
    });
    _searchFocusNode.requestFocus();
  }

  void _showDetails(LanguageCard card) {
    final isEmbedded = card.tableName == 'Embedded' || card.category == CardCategory.embedded;
    final isDistributed = isEmbedded && embeddedSubtypeFor(card) == EmbeddedSubtype.distributed;
    final isComplianceSet = card.tableName == 'Compliance Sets';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1D1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF876E43), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: card.category.color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                card.text,
                style: const TextStyle(color: Color(0xFFF5EEDA), fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLabel(label: 'TABLE', value: card.tableName),
              const SizedBox(height: 16),
              _DetailLabel(label: 'CATEGORY', value: card.category.label, color: card.category.color),
              if (card.tableName == 'Linkages') ...[
                const SizedBox(height: 16),
                _DetailLabel(label: 'LINKAGE STATUS', value: linkageSubtypeLabel(card), color: const Color(0xFFD4AF37)),
              ],
              if (card.tableName == 'Compliance Commands') ...[
                if (primaryComplianceSubtypeFor(card) != null) ...[
                  const SizedBox(height: 16),
                  _DetailLabel(label: 'PRIMARY CLASSIFICATION', value: primaryComplianceSubtypeFor(card)!.label, color: CardCategory.red.color),
                ],
                if (secondaryComplianceSubtypeFor(card) != null) ...[
                  const SizedBox(height: 16),
                  _DetailLabel(label: 'SECONDARY CLASSIFICATION', value: secondaryComplianceSubtypeFor(card)!.label, color: const Color(0xFFD4AF37)),
                ],
              ],
              if (isEmbedded) ...[
                const SizedBox(height: 16),
                _DetailLabel(label: 'EMBEDDED STATUS', value: embeddedSubtypeLabel(card), color: CardCategory.embedded.color),
              ],
              if (isComplianceSet) ...[
                const SizedBox(height: 16),
                _DetailLabel(label: 'SET NAME', value: card.text),
                const SizedBox(height: 16),
                _DetailLabel(label: 'COMMAND COUNT', value: '${card.fragments.length} commands'),
                const SizedBox(height: 16),
                const Text('COMMANDS IN EXACT ORDER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < card.fragments.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}. ', style: const TextStyle(color: Color(0xFF80796C), fontSize: 13)),
                            Expanded(child: Text(card.fragments[i], style: const TextStyle(color: Color(0xFFF1D060), fontSize: 13, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              if (isDistributed) ...[
                const SizedBox(height: 16),
                const Text('FULL CARRIER PASSAGE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF121415), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF38352F))),
                  child: _buildHighlightedPassage(card.passage, card.fragments),
                ),
                const SizedBox(height: 16),
                const Text('COMMAND FRAGMENTS IN ORDER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < card.fragments.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}. ', style: const TextStyle(color: Color(0xFF80796C), fontSize: 13)),
                            Expanded(child: Text(card.fragments[i], style: const TextStyle(color: Color(0xFFF1D060), fontSize: 13, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailLabel(label: 'RECONSTRUCTED COMMAND / INTENT', value: card.reconstructedIntent, color: const Color(0xFFF1D060)),
              ],
              const SizedBox(height: 16),
              _DetailLabel(label: 'REFERENCE NOTE', value: card.referenceNote.isEmpty ? 'No reference note supplied.' : card.referenceNote),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4AF37)),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedPassage(String passage, List<String> fragments) {
    final spans = <TextSpan>[];
    var lastIndex = 0;

    for (final fragment in fragments) {
      if (fragment.isEmpty) continue;
      final index = passage.indexOf(fragment, lastIndex);
      if (index != -1) {
        if (index > lastIndex) {
          spans.add(TextSpan(
            text: passage.substring(lastIndex, index),
            style: const TextStyle(color: Color(0xFFB5ADA0), fontSize: 13, height: 1.4),
          ));
        }
        spans.add(TextSpan(
          text: passage.substring(index, index + fragment.length),
          style: TextStyle(
            color: const Color(0xFFF1D060),
            backgroundColor: CardCategory.embedded.color.withValues(alpha: 0.35),
            fontWeight: FontWeight.bold,
            fontSize: 13,
            height: 1.4,
          ),
        ));
        lastIndex = index + fragment.length;
      }
    }

    if (lastIndex < passage.length) {
      spans.add(TextSpan(
        text: passage.substring(lastIndex),
        style: const TextStyle(color: Color(0xFFB5ADA0), fontSize: 13, height: 1.4),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _ResearchLabPainter()),
          SafeArea(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Return to Gallery Hall',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
                            ),
                            const SizedBox(width: 8),
                            const Text('RESEARCH', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 3.5)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Research Laboratory', style: TextStyle(color: Color(0xFFF5EEDA), fontSize: 38, fontWeight: FontWeight.w400, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        const Text('Explore the language collection across all tables.', style: TextStyle(color: Color(0xFFC2B7A0), fontSize: 16)),
                        const SizedBox(height: 28),
                        _ResearchControls(
                          searchController: _searchController,
                          selectedTable: _selectedTable,
                          onTableChanged: _changeTable,
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (value) => setState(() => _selectedCategory = value),
                          selectedLinkageSubtype: _selectedLinkageSubtype,
                          onLinkageSubtypeChanged: (value) => setState(() => _selectedLinkageSubtype = value),
                          selectedEmbeddedSubtype: _selectedEmbeddedSubtype,
                          onEmbeddedSubtypeChanged: (value) => setState(() => _selectedEmbeddedSubtype = value),
                          selectedComplianceSubtype: _selectedComplianceSubtype,
                          onComplianceSubtypeChanged: (value) => setState(() => _selectedComplianceSubtype = value),
                          onReset: _resetFilters,
                          searchFocusNode: _searchFocusNode,
                        ),
                        const SizedBox(height: 20),
                        Text('${_filteredCards.length} results', key: const ValueKey('research-result-count'), style: const TextStyle(color: Color(0xFF90887A), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        _buildResults(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final cards = _filteredCards;
    if (cards.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFF141617).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6E5935).withValues(alpha: 0.6), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_outlined, size: 36, color: Color(0xFFD4AF37)),
              SizedBox(height: 12),
              Text('No matching cards found', style: TextStyle(color: Color(0xFFF5EEDA), fontSize: 17, fontWeight: FontWeight.w500)),
              SizedBox(height: 6),
              Text('Try adjusting your search terms, table, or category filters.', style: TextStyle(color: Color(0xFFA9A294), fontSize: 13)),
            ],
          ),
        ),
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
  const _ResearchControls({
    required this.searchController,
    required this.selectedTable,
    required this.onTableChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedLinkageSubtype,
    required this.onLinkageSubtypeChanged,
    required this.selectedEmbeddedSubtype,
    required this.onEmbeddedSubtypeChanged,
    required this.selectedComplianceSubtype,
    required this.onComplianceSubtypeChanged,
    required this.onReset,
    required this.searchFocusNode,
  });

  final TextEditingController searchController;
  final String selectedTable;
  final ValueChanged<String> onTableChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String selectedLinkageSubtype;
  final ValueChanged<String> onLinkageSubtypeChanged;
  final String selectedEmbeddedSubtype;
  final ValueChanged<String> onEmbeddedSubtypeChanged;
  final String selectedComplianceSubtype;
  final ValueChanged<String> onComplianceSubtypeChanged;
  final VoidCallback onReset;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    const fieldDecoration = InputDecoration(
      filled: true,
      fillColor: Color(0xFF141617),
      labelStyle: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: Color(0xFF80796C)),
      prefixIconColor: Color(0xFFD4AF37),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6E5935), width: 1.0)),
    );

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
            style: const TextStyle(color: Color(0xFFF5EEDA)),
            decoration: fieldDecoration.copyWith(
              labelText: 'Search language cards',
              hintText: 'Search by card text or table',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        );
        final filter = DropdownButtonFormField<String>(
          initialValue: selectedTable,
          isExpanded: true,
          dropdownColor: const Color(0xFF1B1D1E),
          style: const TextStyle(color: Color(0xFFF5EEDA)),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFD4AF37)),
          key: const ValueKey('research-table-filter'),
          decoration: fieldDecoration.copyWith(labelText: 'Table'),
          items: ['All Tables', ...languageTables.map((table) => table.name)].map((table) => DropdownMenuItem(value: table, child: Text(table, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) {
            if (value != null) onTableChanged(value);
          },
        );
        final categoryFilter = DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          isExpanded: true,
          dropdownColor: const Color(0xFF1B1D1E),
          style: const TextStyle(color: Color(0xFFF5EEDA)),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFD4AF37)),
          key: const ValueKey('research-category-filter'),
          decoration: fieldDecoration.copyWith(labelText: 'Category'),
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
          dropdownColor: const Color(0xFF1B1D1E),
          style: const TextStyle(color: Color(0xFFF5EEDA)),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFD4AF37)),
          key: const ValueKey('research-linkage-subtype-filter'),
          decoration: fieldDecoration.copyWith(labelText: 'Linkage Subtype'),
          items: ['All Linkage Subtypes', 'Basic Linkages', 'Restatement Linkages', 'Momentum Linkages']
              .map((subtype) => DropdownMenuItem(value: subtype, child: Text(subtype, maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (value) {
            if (value != null) onLinkageSubtypeChanged(value);
          },
        );
        final embeddedSubtypeFilter = DropdownButtonFormField<String>(
          initialValue: selectedEmbeddedSubtype,
          isExpanded: true,
          dropdownColor: const Color(0xFF1B1D1E),
          style: const TextStyle(color: Color(0xFFF5EEDA)),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFD4AF37)),
          key: const ValueKey('research-embedded-subtype-filter'),
          decoration: fieldDecoration.copyWith(labelText: 'Embedded Subtype'),
          items: ['All Embedded Subtypes', 'Intact Embedded Commands', 'Distributed Embedded Commands']
              .map((subtype) => DropdownMenuItem(value: subtype, child: Text(subtype, maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (value) {
            if (value != null) onEmbeddedSubtypeChanged(value);
          },
        );
        final complianceSubtypeFilter = DropdownButtonFormField<String>(
          initialValue: selectedComplianceSubtype,
          isExpanded: true,
          dropdownColor: const Color(0xFF1B1D1E),
          style: const TextStyle(color: Color(0xFFF5EEDA)),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFD4AF37)),
          key: const ValueKey('research-compliance-subtype-filter'),
          decoration: fieldDecoration.copyWith(labelText: 'Compliance Subtype'),
          items: ['All Compliance Subtypes', 'Voluntary', 'Involuntary']
              .map((subtype) => DropdownMenuItem(value: subtype, child: Text(subtype, maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (value) {
            if (value != null) onComplianceSubtypeChanged(value);
          },
        );
        final showLinkageSubtype = selectedTable == 'All Tables' || selectedTable == 'Linkages';
        final showEmbeddedSubtype = selectedTable == 'All Tables' || selectedTable == 'Embedded' || selectedCategory == 'Embedded';
        final showComplianceSubtype = selectedTable == 'All Tables' || selectedTable == 'Compliance Commands' || selectedCategory == 'Compliance';
        final reset = Semantics(
          button: true,
          label: 'Reset research filters',
          child: TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 17, color: Color(0xFFD4AF37)),
            label: const Text('Reset Filters'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        );
        if (constraints.maxWidth < 1100) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              search,
              const SizedBox(height: 12),
              filter,
              const SizedBox(height: 12),
              categoryFilter,
              if (showLinkageSubtype) ...[const SizedBox(height: 12), linkageSubtypeFilter],
              if (showEmbeddedSubtype) ...[const SizedBox(height: 12), embeddedSubtypeFilter],
              if (showComplianceSubtype) ...[const SizedBox(height: 12), complianceSubtypeFilter],
              const SizedBox(height: 8),
              reset,
            ],
          );
        }
        return Column(
          children: [
            Row(children: [Expanded(child: search), const SizedBox(width: 14), SizedBox(width: 220, child: filter), const SizedBox(width: 14), SizedBox(width: 220, child: categoryFilter)]),
            if (showLinkageSubtype || showEmbeddedSubtype || showComplianceSubtype) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  if (showLinkageSubtype) SizedBox(width: 220, child: linkageSubtypeFilter),
                  if (showEmbeddedSubtype) SizedBox(width: 220, child: embeddedSubtypeFilter),
                  if (showComplianceSubtype) SizedBox(width: 220, child: complianceSubtypeFilter),
                ],
              ),
            ],
            Align(alignment: Alignment.centerLeft, child: reset),
          ],
        );
      },
    );
  }
}

class _ResearchResultCard extends StatefulWidget {
  const _ResearchResultCard({required this.card, required this.onTap});

  final LanguageCard card;
  final VoidCallback onTap;

  @override
  State<_ResearchResultCard> createState() => _ResearchResultCardState();
}

class _ResearchResultCardState extends State<_ResearchResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.card.category.color;
    final card = widget.card;

    return Semantics(
      button: true,
      label: 'Open research details for ${card.text}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: const Color(0xFF161819),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? color : color.withValues(alpha: 0.65),
              width: _hovered ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? color.withValues(alpha: 0.25) : Colors.black87,
                blurRadius: _hovered ? 14 : 8,
                offset: Offset(0, _hovered ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFF5EEDA), fontSize: 15, height: 1.25, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(card.tableName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFA9A294), fontSize: 11)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          card.category.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF80796C)),
                    ],
                  ),
                  if (card.tableName == 'Linkages') ...[
                    const SizedBox(height: 4),
                    Text(linkageSubtypeLabel(card), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
                  ],
                  if (card.tableName == 'Embedded' || card.category == CardCategory.embedded) ...[
                    const SizedBox(height: 4),
                    Text(embeddedSubtypeLabel(card), overflow: TextOverflow.ellipsis, style: TextStyle(color: CardCategory.embedded.color, fontSize: 10)),
                  ],
                  if (card.tableName == 'Compliance Commands') ...[
                    const SizedBox(height: 4),
                    Text(primaryComplianceSubtypeFor(card)?.label ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(color: card.category.color, fontSize: 10)),
                  ],
                  if (card.tableName == 'Compliance Sets') ...[
                    const SizedBox(height: 4),
                    Text('${card.fragments.length} commands in sequence', overflow: TextOverflow.ellipsis, style: TextStyle(color: card.category.color, fontSize: 10)),
                  ],
                ],
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(color: color ?? const Color(0xFFF5EEDA), fontSize: 14, height: 1.35),
        ),
      ],
    );
  }
}

class _ResearchLabPainter extends CustomPainter {
  const _ResearchLabPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Base library study background gradient
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.15,
        colors: const [
          Color(0xFF202324),
          Color(0xFF141617),
          Color(0xFF0A0B0C),
          Color(0xFF040405),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Warm ambient study desk lighting
    final deskGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 0.75,
        colors: [
          const Color(0xFFD4A325).withValues(alpha: 0.09),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, deskGlow);

    // Subtle stone coursing lines
    final strokePaint = Paint()
      ..color = const Color(0x182C2822)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const blockHeight = 64.0;
    const blockWidth = 100.0;

    for (var row = 0; row < size.height / blockHeight + 1; row++) {
      final y = row * blockHeight;
      final offset = row.isEven ? 0.0 : blockWidth / 2;
      for (var col = -1; col < size.width / blockWidth + 1; col++) {
        final x = col * blockWidth + offset;
        canvas.drawRect(Rect.fromLTWH(x, y, blockWidth - 2, blockHeight - 2), strokePaint);
      }
    }

    // Outer vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
        stops: const [0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
