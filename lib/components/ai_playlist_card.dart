import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/music_store.dart';

class AiPlaylistCard extends StatelessWidget {
  final Map<String, dynamic> playlist;

  const AiPlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final songs = playlist['songs'] as List<dynamic>;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    playlist['name'] ?? 'AI 主题',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () =>
                      context.read<MusicStore>().playPlaylist(songs, 0),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              playlist['basis'] ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: (playlist['tags'] as String).split(',').take(2).map((tag) =>
                Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.purpleAccent)),
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  padding: EdgeInsets.zero,
                  side: BorderSide.none,
                )
              ).toList(),
            ),
          )
        ],
      ),
    );
  }
}
