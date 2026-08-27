import 'language_card.dart';

class ArchivedWork {
  ArchivedWork({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.cards,
  });

  final String id;
  String name;
  DateTime savedAt;
  final List<WorkspaceCard> cards;
}