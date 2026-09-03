import 'package:web/web.dart' as web;

const _developerBoardsKey = 'visual_language_castle.developer_boards';

Future<String?> readDeveloperBoards(Object? fileOverride) async => web.window.localStorage.getItem(_developerBoardsKey);

Future<void> writeDeveloperBoards(Object? fileOverride, String contents) async {
  web.window.localStorage.setItem(_developerBoardsKey, contents);
}