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
  'or should I say',
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
