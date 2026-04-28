import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class LocalMusicLibrary {
  static const String _assetPath = 'assets/data/music_info.json';
  static List<dynamic>? _songs;

  static Future<List<dynamic>> loadSongs() async {
    if (_songs != null) return List<dynamic>.from(_songs!);

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    _songs = decoded is List ? decoded : <dynamic>[];
    return List<dynamic>.from(_songs!);
  }

  static Future<List<dynamic>> search(String keyword) async {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return loadSongs();

    final songs = await loadSongs();
    return songs.where((song) {
      final title = _field(song, 'title').toLowerCase();
      final artist = _field(song, 'artist').toLowerCase();
      final tags = _field(song, 'tags').toLowerCase();
      return title.contains(normalized) ||
          artist.contains(normalized) ||
          tags.contains(normalized);
    }).toList();
  }

  static Future<List<dynamic>> top({int limit = 10}) async {
    final songs = await loadSongs();
    final sorted = List<dynamic>.from(songs)
      ..sort((a, b) => _playCount(b).compareTo(_playCount(a)));
    return sorted.take(limit).toList();
  }

  static Future<List<dynamic>> byArtist(String artist) async {
    final normalized = artist.trim().toLowerCase();
    final songs = await loadSongs();
    if (normalized.isEmpty) return songs;

    return songs.where((song) {
      return _field(song, 'artist').toLowerCase().contains(normalized);
    }).toList();
  }

  static Future<List<dynamic>> recommend(String scene) async {
    final normalized = scene.trim().toLowerCase();
    if (normalized.isEmpty) return top(limit: 8);

    final songs = await loadSongs();
    final scored = songs.map((song) {
      final text =
          '${_field(song, 'title')} ${_field(song, 'artist')} ${_field(song, 'tags')}'
              .toLowerCase();
      final score = normalized
          .split(RegExp(r'\s+|,|，|。|、'))
          .where((part) => part.isNotEmpty && text.contains(part))
          .length;
      return _ScoredSong(song, score);
    }).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return _playCount(b.song).compareTo(_playCount(a.song));
      });

    final matched = scored.where((item) => item.score > 0).toList();
    return (matched.isEmpty ? scored : matched)
        .take(min(8, scored.length))
        .map((item) => item.song)
        .toList();
  }

  static Future<List<dynamic>> generatePlaylists() async {
    final songs = await loadSongs();
    return [
      _playlist('Echo FM', '根据热度自动生成', 'fm,热门', songs, [
        '流行',
        '节奏控',
        '轻松',
      ]),
      _playlist('助眠模式', '适合夜晚和放松', 'sleep,助眠,深夜', songs, [
        '深夜',
        '治愈',
        '纯音乐',
        '雨天',
      ]),
      _playlist('工作学习', '低干扰的本地推荐', '工作学习,咖啡馆,纯音乐', songs, [
        '工作学习',
        '咖啡馆',
        '纯音乐',
      ]),
    ];
  }

  static Map<String, dynamic> _playlist(
    String name,
    String description,
    String tags,
    List<dynamic> songs,
    List<String> preferredTags,
  ) {
    final selected = songs.where((song) {
      final songTags = _field(song, 'tags');
      return preferredTags.any(songTags.contains);
    }).take(12).toList();

    return {
      'name': name,
      'description': description,
      'tags': tags,
      'basis': name.toLowerCase(),
      'songs': selected.isEmpty ? songs.take(12).toList() : selected,
    };
  }

  static String _field(dynamic song, String key) {
    if (song is! Map) return '';
    final value = song[key] ?? song[_snakeKey(key)];
    return value?.toString() ?? '';
  }

  static int _playCount(dynamic song) {
    if (song is! Map) return 0;
    final value = song['playCount'] ?? song['play_count'] ?? 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _snakeKey(String key) {
    return key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}

class _ScoredSong {
  final dynamic song;
  final int score;

  _ScoredSong(this.song, this.score);
}
