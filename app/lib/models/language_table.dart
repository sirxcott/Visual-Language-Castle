import 'language_card.dart';

class LanguageTable {
  const LanguageTable({required this.name, required this.cards});

  final String name;
  final List<LanguageCard> cards;
}

// Linkages are spoken scaffolding between sentences, not commands or
// suggestions. Cause and Effect remains a separate table/function.
