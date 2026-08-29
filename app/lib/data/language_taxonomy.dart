import '../models/language_card.dart';

enum LinkageSubtype {
  restatement,
  momentum,
}

extension LinkageSubtypeDetails on LinkageSubtype {
  String get label {
    switch (this) {
      case LinkageSubtype.restatement:
        return 'Restatement Linkages';
      case LinkageSubtype.momentum:
        return 'Momentum Linkages';
    }
  }
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
  "and if that's the case",
  'and as a result',
  'of course',
  'obviously',
};

LinkageSubtype? linkageSubtypeFor(LanguageCard card) {
  if (card.tableName != 'Linkages') return null;
  final text = card.text.toLowerCase();
  if (_restatementLinkages.contains(text)) return LinkageSubtype.restatement;
  if (_momentumLinkages.contains(text)) return LinkageSubtype.momentum;
  return null;
}

String linkageSubtypeLabel(LanguageCard card) => linkageSubtypeFor(card)?.label ?? 'Unclassified';

enum EmbeddedSubtype {
  intact,
  distributed,
}

extension EmbeddedSubtypeDetails on EmbeddedSubtype {
  String get label {
    switch (this) {
      case EmbeddedSubtype.intact:
        return 'Intact Embedded Commands';
      case EmbeddedSubtype.distributed:
        return 'Distributed Embedded Commands';
    }
  }
}

EmbeddedSubtype? embeddedSubtypeFor(LanguageCard card) {
  if (card.tableName != 'Embedded' && card.category != CardCategory.embedded) return null;
  if (card.passage.isNotEmpty || card.fragments.isNotEmpty) {
    return EmbeddedSubtype.distributed;
  }
  return EmbeddedSubtype.intact;
}

String embeddedSubtypeLabel(LanguageCard card) => embeddedSubtypeFor(card)?.label ?? 'Unclassified';
