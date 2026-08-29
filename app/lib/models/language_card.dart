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
  deepener,
}

// Legacy display categories are retained while the v1 taxonomy is migrated.
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
      case CardCategory.deepener:
        return 'Deepener';
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
        return const Color(0xFFD4A325);
      case CardCategory.embedded:
        return const Color(0xFF8F8140);
      case CardCategory.darkBlue:
        return const Color(0xFF466D9E);
      case CardCategory.lightBlue:
        return const Color(0xFF7893C7);
      case CardCategory.lyModifier:
        return const Color(0xFF66A6B8);
      case CardCategory.tranceWordplay:
        return const Color(0xFF8D527F);
      case CardCategory.deepener:
        // Deep maroon-purple: commands worded to send someone further into trance.
        return const Color(0xFF632050);
    }
  }
}

/// Stable semantic classifications for Language Taxonomy v1.0.
///
/// These are separate from [CardCategory] so the existing UI can continue to
/// use its legacy color categories while cards are migrated incrementally.
enum LanguageClassification {
  nominal,
  verb,
  linkage,
  complianceCommand,
  complianceSet,
  notice,
  embeddedCommand,
  deepener,
  timeBind,
  causeAndEffect,
  lyModifier,
  tranceWordplay,
}

extension LanguageClassificationDetails on LanguageClassification {
  String get label {
    switch (this) {
      case LanguageClassification.nominal:
        return 'Nominal';
      case LanguageClassification.verb:
        return 'Verb';
      case LanguageClassification.linkage:
        return 'Linkage';
      case LanguageClassification.complianceCommand:
        return 'Compliance Command';
      case LanguageClassification.complianceSet:
        return 'Compliance Set';
      case LanguageClassification.notice:
        return 'Notice';
      case LanguageClassification.embeddedCommand:
        return 'Embedded Command';
      case LanguageClassification.deepener:
        return 'Deepener';
      case LanguageClassification.timeBind:
        return 'Time Bind';
      case LanguageClassification.causeAndEffect:
        return 'Cause and Effect';
      case LanguageClassification.lyModifier:
        return 'LY Modifier';
      case LanguageClassification.tranceWordplay:
        return 'Trance Wordplay';
    }
  }
}

LanguageClassification legacyClassificationForCategory(CardCategory category) {
  switch (category) {
    case CardCategory.orange:
      return LanguageClassification.nominal;
    case CardCategory.pink:
      return LanguageClassification.verb;
    case CardCategory.green:
      return LanguageClassification.linkage;
    case CardCategory.red:
      return LanguageClassification.complianceSet;
    case CardCategory.notice:
      return LanguageClassification.notice;
    case CardCategory.embedded:
      return LanguageClassification.embeddedCommand;
    case CardCategory.darkBlue:
      return LanguageClassification.timeBind;
    case CardCategory.lightBlue:
      return LanguageClassification.causeAndEffect;
    case CardCategory.lyModifier:
      return LanguageClassification.lyModifier;
    case CardCategory.tranceWordplay:
      return LanguageClassification.tranceWordplay;
    case CardCategory.deepener:
      return LanguageClassification.deepener;
  }
}

/// Exact classified span inside a larger phrase or carrier passage.
class LanguageSegment {
  const LanguageSegment({
    required this.text,
    required this.classification,
    this.subtype = '',
    this.order = 0,
  });

  final String text;
  final LanguageClassification classification;
  final String subtype;
  final int order;
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
    this.primaryClassification,
    this.secondaryClassifications = const [],
    this.visibleSubtype = '',
    this.internalSubtypes = const [],
    this.definition = '',
    this.primaryFunction = '',
    this.teachingExamples = const [],
    this.usageNotes = '',
    this.referenceNoteIds = const [],
    this.segments = const [],
    this.relatedCardIds = const [],
    this.taxonomyVersion = '1.0',
  });

  final String id;
  final String text;

  // Legacy fields retained until the current corpus/UI migration is complete.
  final CardCategory category;
  final String tableName;
  final String referenceNote;
  final String passage;
  final List<String> fragments;
  final String reconstructedIntent;
  final bool isResearchOnly;

  // Language Taxonomy v1.0 metadata.
  final LanguageClassification? primaryClassification;
  final List<LanguageClassification> secondaryClassifications;
  final String visibleSubtype;
  final List<String> internalSubtypes;
  final String definition;
  final String primaryFunction;
  final List<String> teachingExamples;
  final String usageNotes;
  final List<String> referenceNoteIds;
  final List<LanguageSegment> segments;
  final List<String> relatedCardIds;
  final String taxonomyVersion;

  LanguageClassification get effectivePrimaryClassification =>
      primaryClassification ?? legacyClassificationForCategory(category);

  bool hasClassification(LanguageClassification classification) =>
      effectivePrimaryClassification == classification ||
      secondaryClassifications.contains(classification) ||
      segments.any((segment) => segment.classification == classification);
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
