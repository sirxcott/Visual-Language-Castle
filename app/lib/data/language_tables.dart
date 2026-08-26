import '../models/language_card.dart';
import '../models/language_table.dart';

const languageTables = <LanguageTable>[
  LanguageTable(
    name: 'Nominals',
    cards: [
      LanguageCard(id: 'nom-1', text: 'the room', category: CardCategory.orange, tableName: 'Nominals'),
      LanguageCard(id: 'nom-2', text: 'a possibility', category: CardCategory.orange, tableName: 'Nominals'),
      LanguageCard(id: 'nom-3', text: 'something useful', category: CardCategory.orange, tableName: 'Nominals'),
      LanguageCard(id: 'nom-4', text: 'in a moment', category: CardCategory.orange, tableName: 'Nominals'),
      LanguageCard(id: 'nom-5', text: 'your attention', category: CardCategory.orange, tableName: 'Nominals'),
      LanguageCard(id: 'nom-6', text: 'that feeling', category: CardCategory.orange, tableName: 'Nominals'),
    ],
  ),
  LanguageTable(
    name: 'Verbs',
    cards: [
      LanguageCard(id: 'verb-1', text: 'notice', category: CardCategory.pink, tableName: 'Verbs'),
      LanguageCard(id: 'verb-2', text: 'allow', category: CardCategory.pink, tableName: 'Verbs'),
      LanguageCard(id: 'verb-3', text: 'remember', category: CardCategory.pink, tableName: 'Verbs'),
      LanguageCard(id: 'verb-4', text: 'discover', category: CardCategory.pink, tableName: 'Verbs'),
      LanguageCard(id: 'verb-5', text: 'feel', category: CardCategory.pink, tableName: 'Verbs'),
      LanguageCard(id: 'verb-6', text: 'continue', category: CardCategory.pink, tableName: 'Verbs'),
    ],
  ),
  LanguageTable(
    name: 'Linkages',
    cards: [
      LanguageCard(id: 'link-1', text: 'and', category: CardCategory.green, tableName: 'Linkages'),
      LanguageCard(id: 'link-2', text: 'because', category: CardCategory.green, tableName: 'Linkages'),
      LanguageCard(id: 'link-3', text: 'as', category: CardCategory.green, tableName: 'Linkages'),
      LanguageCard(id: 'link-4', text: 'while', category: CardCategory.green, tableName: 'Linkages'),
      LanguageCard(id: 'link-5', text: 'which means', category: CardCategory.green, tableName: 'Linkages'),
    ],
  ),
  LanguageTable(
    name: 'Compliance Set',
    cards: [
      LanguageCard(id: 'comp-1', text: 'Relax your eyes', category: CardCategory.red, tableName: 'Compliance Set'),
      LanguageCard(id: 'comp-2', text: 'Make yourself comfortable', category: CardCategory.red, tableName: 'Compliance Set'),
      LanguageCard(id: 'comp-3', text: 'Let your breathing settle', category: CardCategory.red, tableName: 'Compliance Set'),
      LanguageCard(id: 'comp-4', text: 'In a moment, I\'m going to ask you to relax', category: CardCategory.red, tableName: 'Compliance Set'),
    ],
  ),
  LanguageTable(
    name: 'Noticing / Embedded',
    cards: [
      LanguageCard(id: 'notice-1', text: 'you may notice', category: CardCategory.yellow, tableName: 'Noticing / Embedded'),
      LanguageCard(id: 'notice-2', text: 'you can begin to', category: CardCategory.yellow, tableName: 'Noticing / Embedded'),
      LanguageCard(id: 'notice-3', text: 'as you become aware', category: CardCategory.yellow, tableName: 'Noticing / Embedded'),
      LanguageCard(id: 'notice-4', text: 'it is interesting to notice', category: CardCategory.yellow, tableName: 'Noticing / Embedded'),
    ],
  ),
  LanguageTable(
    name: 'Time Binds',
    cards: [
      LanguageCard(id: 'time-1', text: 'before you', category: CardCategory.darkBlue, tableName: 'Time Binds'),
      LanguageCard(id: 'time-2', text: 'while you', category: CardCategory.darkBlue, tableName: 'Time Binds'),
      LanguageCard(id: 'time-3', text: 'after you', category: CardCategory.darkBlue, tableName: 'Time Binds'),
      LanguageCard(id: 'time-4', text: 'now that', category: CardCategory.darkBlue, tableName: 'Time Binds'),
    ],
  ),
  LanguageTable(
    name: 'Cause and Effect',
    cards: [
      LanguageCard(id: 'cause-1', text: 'which allows', category: CardCategory.lightBlue, tableName: 'Cause and Effect'),
      LanguageCard(id: 'cause-2', text: 'so that', category: CardCategory.lightBlue, tableName: 'Cause and Effect'),
      LanguageCard(id: 'cause-3', text: 'because of this', category: CardCategory.lightBlue, tableName: 'Cause and Effect'),
      LanguageCard(id: 'cause-4', text: 'and that means', category: CardCategory.lightBlue, tableName: 'Cause and Effect'),
    ],
  ),
  LanguageTable(
    name: 'LY Modifiers',
    cards: [
      LanguageCard(id: 'ly-1', text: 'comfortably', category: CardCategory.lyModifier, tableName: 'LY Modifiers'),
      LanguageCard(id: 'ly-2', text: 'curiously', category: CardCategory.lyModifier, tableName: 'LY Modifiers'),
      LanguageCard(id: 'ly-3', text: 'gradually', category: CardCategory.lyModifier, tableName: 'LY Modifiers'),
      LanguageCard(id: 'ly-4', text: 'easily', category: CardCategory.lyModifier, tableName: 'LY Modifiers'),
    ],
  ),
];
