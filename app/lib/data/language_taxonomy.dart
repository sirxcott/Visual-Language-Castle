import '../models/language_card.dart';

/// Language Taxonomy v1.0 visible subtype: Compliance Commands.
enum ComplianceSubtype { voluntary, involuntary }

extension ComplianceSubtypeDetails on ComplianceSubtype {
  String get label => switch (this) {
        ComplianceSubtype.voluntary => 'Voluntary Compliance Commands',
        ComplianceSubtype.involuntary => 'Involuntary Compliance Commands',
      };
}

/// Language Taxonomy v1.0 visible subtype: Notice.
enum NoticeSubtype { command, statement }

extension NoticeSubtypeDetails on NoticeSubtype {
  String get label => switch (this) {
        NoticeSubtype.command => 'Notice Commands',
        NoticeSubtype.statement => 'Notice Statements',
      };
}

/// Internal filters for Notice Statements. These are not separate Tables.
enum NoticeStatementFilter { permissive, tentative, predictivePresuppositional }

extension NoticeStatementFilterDetails on NoticeStatementFilter {
  String get label => switch (this) {
        NoticeStatementFilter.permissive => 'Permissive',
        NoticeStatementFilter.tentative => 'Tentative',
        NoticeStatementFilter.predictivePresuppositional => 'Predictive / Presuppositional',
      };
}

/// Language Taxonomy v1.0 visible subtype: Embedded Commands.
enum EmbeddedSubtype { intact, distributed }

extension EmbeddedSubtypeDetails on EmbeddedSubtype {
  String get label => switch (this) {
        EmbeddedSubtype.intact => 'Intact Embedded Commands',
        EmbeddedSubtype.distributed => 'Distributed Embedded Commands',
      };
}

/// Language Taxonomy v1.0 visible subtype: Deepeners.
enum DeepenerSubtype { direct, progressive, intensification, maintenanceReinforcement }

extension DeepenerSubtypeDetails on DeepenerSubtype {
  String get label => switch (this) {
        DeepenerSubtype.direct => 'Direct',
        DeepenerSubtype.progressive => 'Progressive',
        DeepenerSubtype.intensification => 'Intensification',
        DeepenerSubtype.maintenanceReinforcement => 'Maintenance / Reinforcement',
      };
}

/// Internal Nominal filters. These are not separate Tables.
enum NominalFilter { resource, personalQuality, processDerived, experientialMeasurement }

extension NominalFilterDetails on NominalFilter {
  String get label => switch (this) {
        NominalFilter.resource => 'Resource',
        NominalFilter.personalQuality => 'Personal Quality',
        NominalFilter.processDerived => 'Process-derived / Nominalization',
        NominalFilter.experientialMeasurement => 'Experiential Measurement / Dimension',
      };
}

/// Internal LY Modifier filters. These are not separate Tables.
enum LyModifierFilter { degreeIntensity, paceProgression, easeEffort, stateQuality }

extension LyModifierFilterDetails on LyModifierFilter {
  String get label => switch (this) {
        LyModifierFilter.degreeIntensity => 'Degree / Intensity',
        LyModifierFilter.paceProgression => 'Pace / Progression',
        LyModifierFilter.easeEffort => 'Ease / Effort',
        LyModifierFilter.stateQuality => 'State Quality',
      };
}

/// Internal Time Bind filters. The v1.0 core stems remain content, not enum cases.
enum TimeBindFilter { simultaneous, sequential, continuationEndpoint, eventPeriod }

extension TimeBindFilterDetails on TimeBindFilter {
  String get label => switch (this) {
        TimeBindFilter.simultaneous => 'Simultaneous',
        TimeBindFilter.sequential => 'Sequential',
        TimeBindFilter.continuationEndpoint => 'Continuation / Endpoint',
        TimeBindFilter.eventPeriod => 'Event / Period',
      };
}

/// Internal Cause and Effect filters. These are not separate Tables.
enum CauseEffectFilter { directCausation, meaningImplication, progressiveContingent }

extension CauseEffectFilterDetails on CauseEffectFilter {
  String get label => switch (this) {
        CauseEffectFilter.directCausation => 'Direct Causation',
        CauseEffectFilter.meaningImplication => 'Meaning / Implication',
        CauseEffectFilter.progressiveContingent => 'Progressive / Contingent',
      };
}

/// Internal Linkage filters. These replace Restatement/Momentum as the v1 model.
enum LinkageFilter { additive, contrastive, alternative, sequentialContinuative, relationalStructural }

extension LinkageFilterDetails on LinkageFilter {
  String get label => switch (this) {
        LinkageFilter.additive => 'Additive',
        LinkageFilter.contrastive => 'Contrastive',
        LinkageFilter.alternative => 'Alternative',
        LinkageFilter.sequentialContinuative => 'Sequential / Continuative',
        LinkageFilter.relationalStructural => 'Relational / Structural',
      };
}

/// The eight locked core Time Bind stems in Language Taxonomy v1.0.
const coreTimeBindStems = <String>[
  'before',
  'after',
  'while',
  'when',
  'as',
  'once you',
  'now that',
  'during',
];

/// Legacy Linkage subtypes are retained temporarily so the current UI can be
/// migrated without a breaking change. New content should use [LinkageFilter].
@Deprecated('Use LinkageFilter for Language Taxonomy v1.0 content.')
enum LinkageSubtype { restatement, momentum }

@Deprecated('Use LinkageFilterDetails for Language Taxonomy v1.0 content.')
extension LinkageSubtypeDetails on LinkageSubtype {
  String get label => switch (this) {
        LinkageSubtype.restatement => 'Restatement Linkages',
        LinkageSubtype.momentum => 'Momentum Linkages',
      };
}

const _restatementLinkages = {
  'or should i say',
  'or you could say',
  'in other words',
  'which is to say',
  'to put it another way',
  'or rather',
};

const _momentumLinkages = {
  'and',
  'because',
  'as',
  'while',
  "and if that's the case",
  'and as a result',
  'of course',
  'obviously',
};

/// Legacy helper retained during migration.
LinkageSubtype? linkageSubtypeFor(LanguageCard card) {
  if (card.tableName != 'Linkages') return null;
  final text = card.text.toLowerCase();
  if (_restatementLinkages.contains(text)) return LinkageSubtype.restatement;
  if (_momentumLinkages.contains(text)) return LinkageSubtype.momentum;
  return null;
}

/// Legacy helper retained during migration.
String linkageSubtypeLabel(LanguageCard card) => linkageSubtypeFor(card)?.label ?? 'Unclassified';

EmbeddedSubtype? embeddedSubtypeFor(LanguageCard card) {
  if (card.visibleSubtype == EmbeddedSubtype.intact.name) {
    return EmbeddedSubtype.intact;
  }
  if (card.visibleSubtype == EmbeddedSubtype.distributed.name) {
    return EmbeddedSubtype.distributed;
  }
  if (card.tableName != 'Embedded' &&
      !card.hasClassification(LanguageClassification.embeddedCommand)) {
    return null;
  }
  if (card.passage.isNotEmpty || card.fragments.isNotEmpty || card.segments.length >= 2) {
    return EmbeddedSubtype.distributed;
  }
  return EmbeddedSubtype.intact;
}

String embeddedSubtypeLabel(LanguageCard card) => embeddedSubtypeFor(card)?.label ?? 'Unclassified';
