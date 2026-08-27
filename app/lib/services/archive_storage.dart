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
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return decoded.map((item) => _fromJson(item as Map<String, dynamic>)).toList();
    } on Object {
      return [];
    }
  }

  Future<void> saveWorks(List<ArchivedWork> works) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(works.map(_toJson).toList()));
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
    final cards = (json['cards'] as List<dynamic>).map((item) {
      final card = item as Map<String, dynamic>;
      return WorkspaceCard(
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
    final connections = (json['connections'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .where((connection) => connection['from'] is String && connection['to'] is String)
      .map((connection) => CardConnection(fromCardId: connection['from'] as String, toCardId: connection['to'] as String))
      .toList();
    final completedAtValue = json['completedAt'];
    final completedAt = completedAtValue is String ? DateTime.tryParse(completedAtValue) : null;
    return ArchivedWork(
      id: json['id'] as String,
      name: json['name'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      cards: cards,
      connections: connections,
      isCompleted: json['isCompleted'] is bool ? json['isCompleted'] as bool : false,
      completedAt: completedAt,
    );
  }
}