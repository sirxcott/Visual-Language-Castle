import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/developer_board.dart';
import 'developer_board_storage_platform.dart'
    if (dart.library.io) 'developer_board_storage_platform_io.dart'
    if (dart.library.js_interop) 'developer_board_storage_platform_web.dart' as platform;

class DeveloperBoardStorage {
  DeveloperBoardStorage._({this.fileOverride, this._memoryBoards});

  DeveloperBoardStorage.inMemory([List<DeveloperBoard> boards = const []]) : this._(memoryBoards: List<DeveloperBoard>.of(boards));

  static final instance = DeveloperBoardStorage._();

  final Object? fileOverride;
  final List<DeveloperBoard>? _memoryBoards;

  Future<List<DeveloperBoard>> loadBoards() async {
    if (_memoryBoards != null) return _memoryBoards.map((board) => board.copy()).toList();
    final contents = await platform.readDeveloperBoards(fileOverride);
    if (contents == null) return [];
    try {
      return decodeBoards(contents);
    } on Object {
      return [];
    }
  }

  Future<void> saveBoards(List<DeveloperBoard> boards) async {
    if (_memoryBoards != null) {
      _memoryBoards
        ..clear()
        ..addAll(boards.map((board) => board.copy()));
      return;
    }
    await platform.writeDeveloperBoards(fileOverride, encodeBoards(boards));
  }

  String encodeBoards(List<DeveloperBoard> boards) => jsonEncode(boards.map(_boardToJson).toList());

  List<DeveloperBoard> decodeBoards(String contents) {
    final decoded = jsonDecode(contents) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().map(_boardFromJson).toList();
  }

  String exportBoard(DeveloperBoard board) => jsonEncode(_boardToJson(board));

  Map<String, dynamic> _boardToJson(DeveloperBoard board) => {
        'id': board.id,
        'name': board.name,
        'savedAt': board.savedAt.toUtc().toIso8601String(),
        'notes': board.notes
            .map((note) => {
                  'id': note.id,
                  'text': note.text,
                  'researchNotes': note.researchNotes,
                  'category': note.category.name,
                  'color': note.colorValue,
                  'x': note.position.dx,
                  'y': note.position.dy,
                })
            .toList(),
      };

  DeveloperBoard _boardFromJson(Map<String, dynamic> json) => DeveloperBoard(
        id: json['id'] as String,
        name: json['name'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        notes: (json['notes'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((note) => DeveloperNote(
                  id: note['id'] as String,
                  text: note['text'] as String,
                  researchNotes: note['researchNotes'] as String? ?? '',
                  colorValue: note['color'] as int,
                  position: Offset((note['x'] as num).toDouble(), (note['y'] as num).toDouble()),
                  category: DeveloperCategoryDetails.fromStored(note['category']),
                ))
            .toList(),
      );
}