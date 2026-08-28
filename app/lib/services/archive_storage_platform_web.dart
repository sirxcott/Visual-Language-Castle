import 'package:web/web.dart' as web;

const _archiveKey = 'visual_language_castle.archives';

Future<String?> readArchive(Object? fileOverride) async {
  return web.window.localStorage.getItem(_archiveKey);
}

Future<void> writeArchive(Object? fileOverride, String contents) async {
  web.window.localStorage.setItem(_archiveKey, contents);
}
