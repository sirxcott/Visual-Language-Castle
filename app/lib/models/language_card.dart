import 'package:flutter/material.dart';

enum CardCategory {
  orange,
  pink,
  green,
  red,
  yellow,
  darkBlue,
  lightBlue,
  lyModifier,
}

extension CardCategoryDetails on CardCategory {
  String get label {
    switch (this) {
      case CardCategory.orange:
        return 'Nominal';
      case CardCategory.pink:
        return 'Verb';
      case CardCategory.green:
        return 'Linkage';
      case CardCategory.red:
        return 'Compliance Set';
      case CardCategory.yellow:
        return 'Noticing';
      case CardCategory.darkBlue:
        return 'Time Bind';
      case CardCategory.lightBlue:
        return 'Cause and Effect';
      case CardCategory.lyModifier:
        return 'LY Modifier';
    }
  }

  Color get color {
    switch (this) {
      case CardCategory.orange:
        return const Color(0xFFC96A32);
      case CardCategory.pink:
        return const Color(0xFFC55B78);
      case CardCategory.green:
        return const Color(0xFF5D9A78);
      case CardCategory.red:
        return const Color(0xFFB94D4B);
      case CardCategory.yellow:
        return const Color(0xFFC2A650);
      case CardCategory.darkBlue:
        return const Color(0xFF466D9E);
      case CardCategory.lightBlue:
        return const Color(0xFF66A6B8);
      case CardCategory.lyModifier:
        return const Color(0xFF7893C7);
    }
  }
}

class LanguageCard {
  const LanguageCard({
    required this.id,
    required this.text,
    required this.category,
    required this.tableName,
  });

  final String id;
  final String text;
  final CardCategory category;
  final String tableName;
}

class WorkspaceCard {
  WorkspaceCard({
    required this.card,
    required this.position,
    this.notes = '',
  });

  final LanguageCard card;
  Offset position;
  String notes;
}
