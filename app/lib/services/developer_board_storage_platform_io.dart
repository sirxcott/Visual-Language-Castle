import 'dart:io';

Future<String?> readDeveloperBoards(Object? fileOverride) async {
  final file = fileOverride is File ? fileOverride : await _defaultFile;
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeDeveloperBoards(Object? fileOverride, String contents) async {
  final file = fileOverride is File ? fileOverride : await _defaultFile;
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

Future<File> get _defaultFile async {
  final root = Platform.environment['APPDATA'] ?? Platform.environment['HOME'] ?? Directory.systemTemp.path;
  return File('$root${Platform.pathSeparator}VisualLanguageCastle${Platform.pathSeparator}developer_boards.json');
}