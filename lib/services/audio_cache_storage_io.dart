import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> getCachedAudioPath(String cacheKey, String sourceUrl) async {
  final file = await _audioCacheFile(cacheKey, sourceUrl);
  return file.existsSync() ? file.path : null;
}

Future<String?> cacheAudioFromUrl(String cacheKey, String sourceUrl) async {
  final file = await _audioCacheFile(cacheKey, sourceUrl);
  if (file.existsSync()) return file.path;

  await file.parent.create(recursive: true);
  final tempFile = File('${file.path}.download');

  try {
    await Dio().download(sourceUrl, tempFile.path);
    if (await tempFile.length() == 0) {
      await tempFile.delete();
      return null;
    }
    if (file.existsSync()) await file.delete();
    await tempFile.rename(file.path);
    return file.path;
  } catch (_) {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    return null;
  }
}

Future<File> _audioCacheFile(String cacheKey, String sourceUrl) async {
  final directory = await getApplicationDocumentsDirectory();
  final extension = _extensionFromUrl(sourceUrl);
  return File('${directory.path}/echo_music_cache/audio/$cacheKey$extension');
}

String _extensionFromUrl(String sourceUrl) {
  final path = Uri.tryParse(sourceUrl)?.path.toLowerCase() ?? sourceUrl;
  final match = RegExp(r'\.(mp3|m4a|aac|wav|flac|ogg|opus)$').firstMatch(path);
  return match?.group(0) ?? '.mp3';
}
