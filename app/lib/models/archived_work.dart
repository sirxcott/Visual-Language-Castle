import 'language_card.dart';

class ArchivedWork {
  ArchivedWork({
    required this.id,
    required this.name,
    required this.savedAt,
    required this.cards,
    this.connections = const [],
  });

  final String id;
  String name;
  DateTime savedAt;
  final List<WorkspaceCard> cards;
  final List<CardConnection> connections;
}

class CardConnection {
  const CardConnection({required this.fromCardId, required this.toCardId});

  final String fromCardId;
  final String toCardId;
}