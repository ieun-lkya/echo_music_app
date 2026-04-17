import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../stores/music_store.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final musicStore = context.watch<MusicStore>();
    final currentSong = musicStore.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              currentSong['coverUrl'] ?? 'https://via.placeholder.com/50',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.music_note, size: 48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentSong['title'] ?? '未知歌曲',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentSong['artist'] ?? '未知歌手',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          StreamBuilder<PlayerState>(
            stream: musicStore.audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  width: 32.0,
                  height: 32.0,
                  child: const CircularProgressIndicator(),
                );
              } else if (playing != true) {
                return IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  iconSize: 42,
                  color: Colors.blueAccent,
                  onPressed: musicStore.togglePlay,
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.pause_circle_filled),
                  iconSize: 42,
                  color: Colors.blueAccent,
                  onPressed: musicStore.togglePlay,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
