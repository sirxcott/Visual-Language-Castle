import 'package:flutter/material.dart';

enum CardCategory {
  orange,
  pink,
  green,
  red,
  notice,
  embedded,
  darkBlue,
  lightBlue,
  lyModifier,
  tranceWordplay,
}

// Tables contain categories; a phrase may overlap categories when it serves
// multiple functions. These blue-family colors describe the current practical
// model and are intentionally provisional rather than academic taxonomy.
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
      case CardCategory.notice:
        return 'Notice';
      case CardCategory.embedded:
        return 'Embedded';
      case CardCategory.darkBlue:
        return 'Time Bind';
      case CardCategory.lightBlue:
        return 'Cause and Effect';
      case CardCategory.lyModifier:
        return 'LY Modifier';
      case CardCategory.tranceWordplay:
        return 'Trance Wordplay';
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
      case CardCategory.notice:
        // Bright yellow: Notice Statements / Notice Commands that direct attention.
        return const Color(0xFFD4A325);
      case CardCategory.embedded:
        // Muted/dull yellow: Embedded Commands hidden or distributed inside sentences.
        return const Color(0xFF8F8140);
      case CardCategory.darkBlue:
        // Standard blue: temporal structures that locate or bind events.
        return const Color(0xFF466D9E);
      case CardCategory.lightBlue:
        // Dark blue: a condition leading to an implied result.
        return const Color(0xFF7893C7);
      case CardCategory.lyModifier:
        // Light blue: ongoing process and current moment experience.
        return const Color(0xFF66A6B8);
      case CardCategory.tranceWordplay:
        return const Color(0xFF8D527F);
    }
  }
}

class LanguageCard {
  const LanguageCard({
    required this.id,
    required this.text,
    required this.category,
    required this.tableName,
    this.referenceNote = '',
    this.passage = '',
    this.fragments = const [],
    this.reconstructedIntent = '',
    this.isResearchOnly = false,
  });

  final String id;
  final String text;
  final CardCategory category;
  final String tableName;
  final String referenceNote;
  final String passage;
  final List<String> fragments;
  final String reconstructedIntent;
  final bool isResearchOnly;
}

class WorkspaceCard {
  WorkspaceCard({
    required this.card,
    required this.position,
    String? instanceId,
    this.notes = '',
  }) : instanceId = instanceId ?? _newWorkspaceInstanceId();

  final LanguageCard card;
  final String instanceId;
  Offset position;
  String notes;
}

var _workspaceInstanceSequence = 0;

String _newWorkspaceInstanceId() {
  _workspaceInstanceSequence++;
  return 'workspace-${DateTime.now().microsecondsSinceEpoch}-$_workspaceInstanceSequence';
}
