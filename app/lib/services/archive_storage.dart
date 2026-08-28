import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/archived_work.dart';
import '../models/language_card.dart';

class ArchiveStorage {
  ArchiveStorage._();

  static final ArchiveStorage instance = ArchiveStorage._();

  Future<List<ArchivedWork>> loadWorks() async {
    final file = await _file;
    if (!await file.exists()) return [];
    try {
      return decodeWorks(await file.readAsString());
    } on Object {
      return [];
    }
  }

  List<ArchivedWork> decodeWorks(String contents) {
    final decoded = jsonDecode(contents);
    if (decoded is! List<dynamic>) return [];
    final works = <ArchivedWork>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      try {
        works.add(_fromJson(item));
      } on Object {
        continue;
      }
    }
    return works;
  }

  Future<void> saveWorks(List<ArchivedWork> works) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(encodeWorks(works));
  }

  String encodeWorks(List<ArchivedWork> works) => jsonEncode(works.map(_toJson).toList());

  ArchivedWork createCopy({required String name, required List<WorkspaceCard> cards, required List<CardConnection> connections}) {
    return ArchivedWork(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      savedAt: DateTime.now(),
      cards: cards.map((card) => WorkspaceCard(instanceId: card.instanceId, card: card.card, position: card.position, notes: card.notes)).toList(),
      connections: List<CardConnection>.of(connections),
    );
  }

  List<ArchivedWork> replaceWork(List<ArchivedWork> works, ArchivedWork updated) {
    final replacement = List<ArchivedWork>.of(works);
    final index = replacement.indexWhere((work) => work.id == updated.id);
    if (index >= 0) replacement[index] = updated;
    return replacement;
  }

  Future<File> get _file async {
    final root = Platform.environment['APPDATA'] ?? Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return File('$root${Platform.pathSeparator}VisualLanguageCastle${Platform.pathSeparator}archives.json');
  }

  Map<String, dynamic> _toJson(ArchivedWork work) {
    return {
      'id': work.id,
      'name': work.name,
      'savedAt': work.savedAt.toIso8601String(),
      'cards': work.cards.map((workspaceCard) {
        final card = workspaceCard.card;
        return {
          'id': card.id,
            'instanceId': workspaceCard.instanceId,
          'text': card.text,
          'category': card.category.name,
          'tableName': card.tableName,
          'referenceNote': card.referenceNote,
          'notes': workspaceCard.notes,
          'x': workspaceCard.position.dx,
          'y': workspaceCard.position.dy,
        };
      }).toList(),
      'connections': work.connections.map((connection) => {
        'from': connection.fromCardId,
        'to': connection.toCardId,
      }).toList(),
      'isCompleted': work.isCompleted,
      'completedAt': work.completedAt?.toIso8601String(),
    };
  }

  ArchivedWork _fromJson(Map<String, dynamic> json) {
    final archiveId = json['id'] as String;
    final rawCards = json['cards'] as List<dynamic>;
    final cards = rawCards.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final card = item as Map<String, dynamic>;
      return WorkspaceCard(
        instanceId: card['instanceId'] as String? ?? 'legacy-$archiveId-$index',
        card: LanguageCard(
          id: card['id'] as String,
          text: card['text'] as String,
          category: CardCategory.values.byName(card['category'] as String),
          tableName: card['tableName'] as String,
          referenceNote: card['referenceNote'] as String? ?? '',
        ),
        notes: card['notes'] as String? ?? '',
        position: Offset((card['x'] as num).toDouble(), (card['y'] as num).toDouble()),
      );
    }).toList();
    final cardInstancesBySourceId = <String, List<String>>{};
    for (final workspaceCard in cards) {
      cardInstancesBySourceId.putIfAbsent(workspaceCard.card.id, () => []).add(workspaceCard.instanceId);
    }
    final instanceIds = cards.map((card) => card.instanceId).toSet();
    final rawConnections = json['connections'];
    final connections = (rawConnections is List<dynamic> ? rawConnections : const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .where((connection) => connection['from'] is String && connection['to'] is String)
      .map((connection) {
        final from = connection['from'] as String;
        final to = connection['to'] as String;
        final fromId = instanceIds.contains(from) ? from : cardInstancesBySourceId[from]?.firstOrNull;
        final toId = instanceIds.contains(to) ? to : cardInstancesBySourceId[to]?.firstOrNull;
        if (fromId == null || toId == null) return null;
        return CardConnection(fromCardId: fromId, toCardId: toId);
      })
      .whereType<CardConnection>()
      .toList();
    final completedAtValue = json['completedAt'];
    final completedAt = completedAtValue is String ? DateTime.tryParse(completedAtValue) : null;
    return ArchivedWork(
      id: archiveId,
      name: json['name'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      cards: cards,
      connections: connections,
      isCompleted: json['isCompleted'] is bool ? json['isCompleted'] as bool : false,
      completedAt: completedAt,
    );
  }
}