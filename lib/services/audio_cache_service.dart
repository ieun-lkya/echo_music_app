import 'package:flutter/foundation.dart';

import 'audio_cache_storage_stub.dart'
    if (dart.library.io) 'audio_cache_storage_io.dart'
    as storage;

class AudioCacheService {
  Future<List<dynamic>> cachedSongs(List<dynamic> songs) async {
    final result = <dynamic>[];
    for (final song in songs) {
      if (song is Map) {
        final normalizedSong = Map<String, dynamic>.from(song);
        final cachedPath = await cachedPathFor(normalizedSong);
        if (cachedPath != null) {
          result.add(normalizedSong);
        }
      }
    }
    return result;
  }

  Future<void> cacheSongs(List<dynamic> songs) async {
    for (final song in songs) {
      if (song is Map) {
        await cacheFromSong(Map<String, dynamic>.from(song));
      }
    }
  }

  Future<String?> cachedPathFor(Map<String, dynamic> song) async {
    final sourceUrl = _audioUrl(song);
    if (sourceUrl == null || sourceUrl.startsWith('assets/')) return null;

    try {
      return storage.getCachedAudioPath(_cacheKey(song, sourceUrl), sourceUrl);
    } catch (error) {
      debugPrint('Read audio cache failed: $error');
      return null;
    }
  }

  Future<String?> cacheFromSong(Map<String, dynamic> song) async {
    final sourceUrl = _audioUrl(song);
    if (sourceUrl == null || sourceUrl.startsWith('assets/')) return null;

    try {
      return storage.cacheAudioFromUrl(_cacheKey(song, sourceUrl), sourceUrl);
    } catch (error) {
      debugPrint('Save audio cache failed: $error');
      return null;
    }
  }

  String? audioUrlFor(Map<String, dynamic> song) => _audioUrl(song);

  String? _audioUrl(Map<String, dynamic> song) {
    final value = song['audioUrl'] ?? song['audio_url'];
    final source = value?.toString().trim();
    return source == null || source.isEmpty ? null : source;
  }

  String _cacheKey(Map<String, dynamic> song, String sourceUrl) {
    final id = song['id']?.toString();
    if (id != null && id.isNotEmpty) return _sanitize(id);
    return _sanitize(Uri.encodeComponent(sourceUrl));
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
