import 'package:flutter/material.dart';

class MusicCover extends StatelessWidget {
  final dynamic song;
  final double size;
  final double radius;
  final Color? placeholderColor;
  final Color? iconColor;

  const MusicCover({
    super.key,
    required this.song,
    this.size = 50,
    this.radius = 4,
    this.placeholderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final source = _coverSource(song);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: _buildImage(source),
    );
  }

  Widget _buildImage(String? source) {
    if (source == null || source.isEmpty) {
      return _placeholder();
    }

    if (_isAsset(source)) {
      return Image.asset(
        source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Image.network(
      source,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: placeholderColor ?? Colors.grey.withValues(alpha: 0.16),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        size: size * 0.58,
        color: iconColor ?? Colors.grey,
      ),
    );
  }

  static String? _coverSource(dynamic song) {
    if (song is! Map) return null;
    return (song['coverUrl'] ?? song['cover_url'])?.toString();
  }

  static bool _isAsset(String source) {
    return source.startsWith('assets/') || source.startsWith('asset://');
  }
}
