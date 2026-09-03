import 'package:flutter/material.dart';

import 'language_card.dart';

enum DeveloperCategory {
  nominal,
  verb,
  linkage,
  compliance,
  notice,
  embedded,
  timeBind,
  causeAndEffect,
  lyModifier,
  tranceWordplay,
  deepener,
  unknown,
}

extension DeveloperCategoryDetails on DeveloperCategory {
  String get label => switch (this) {
        DeveloperCategory.nominal => 'Nominal',
        DeveloperCategory.verb => 'Verb',
        DeveloperCategory.linkage => 'Linkage',
        DeveloperCategory.compliance => 'Compliance',
        DeveloperCategory.notice => 'Notice',
        DeveloperCategory.embedded => 'Embedded',
        DeveloperCategory.timeBind => 'Time Bind',
        DeveloperCategory.causeAndEffect => 'Cause and Effect',
        DeveloperCategory.lyModifier => 'LY Modifier',
        DeveloperCategory.tranceWordplay => 'Trance Wordplay',
        DeveloperCategory.deepener => 'Deepener',
        DeveloperCategory.unknown => 'Legacy / Unknown',
      };

  CardCategory? get cardCategory => switch (this) {
        DeveloperCategory.nominal => CardCategory.orange,
        DeveloperCategory.verb => CardCategory.pink,
        DeveloperCategory.linkage => CardCategory.green,
        DeveloperCategory.compliance => CardCategory.red,
        DeveloperCategory.notice => CardCategory.notice,
        DeveloperCategory.embedded => CardCategory.embedded,
        DeveloperCategory.timeBind => CardCategory.darkBlue,
        DeveloperCategory.causeAndEffect => CardCategory.lightBlue,
        DeveloperCategory.lyModifier => CardCategory.lyModifier,
        DeveloperCategory.tranceWordplay => CardCategory.tranceWordplay,
        DeveloperCategory.deepener => CardCategory.deepener,
        DeveloperCategory.unknown => null,
      };

  Color get color => cardCategory?.color ?? const Color(0xFF8A8173);

  static DeveloperCategory? fromStored(Object? value) {
    if (value is! String) return null;
    for (final category in DeveloperCategory.values) {
      if (category.name == value) return category;
    }
    return switch (value) {
      'orange' => DeveloperCategory.nominal,
      'pink' => DeveloperCategory.verb,
      'green' => DeveloperCategory.linkage,
      'red' => DeveloperCategory.compliance,
      'notice' => DeveloperCategory.notice,
      'embedded' => DeveloperCategory.embedded,
      'darkBlue' => DeveloperCategory.timeBind,
      'lightBlue' => DeveloperCategory.causeAndEffect,
      'lyModifier' => DeveloperCategory.lyModifier,
      'tranceWordplay' => DeveloperCategory.tranceWordplay,
      'deepener' => DeveloperCategory.deepener,
      _ => DeveloperCategory.unknown,
    };
  }
}

class DeveloperNote {
  DeveloperNote({
    required this.id,
    required this.text,
    required this.researchNotes,
    required int colorValue,
    required this.position,
    DeveloperCategory? category,
  })  : category = category ?? DeveloperCategory.unknown,
        _legacyColorValue = colorValue;

  final String id;
  String text;
  String researchNotes;
  DeveloperCategory category;
  final int _legacyColorValue;
  Offset position;

  int get colorValue => category == DeveloperCategory.unknown ? _legacyColorValue : category.color.toARGB32();
  Color get color => category.color;

  DeveloperNote copy() => DeveloperNote(
        id: id,
        text: text,
        researchNotes: researchNotes,
        colorValue: colorValue,
        position: position,
        category: category,
      );
}

class DeveloperBoard {
  DeveloperBoard({required this.id, required this.name, required this.savedAt, required this.notes});

  final String id;
  String name;
  DateTime savedAt;
  final List<DeveloperNote> notes;

  DeveloperBoard copy() => DeveloperBoard(
        id: id,
        name: name,
        savedAt: savedAt,
        notes: notes.map((note) => note.copy()).toList(),
      );
}