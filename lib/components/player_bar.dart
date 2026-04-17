import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../stores/music_store.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final musicStore = context.watch<MusicStore>();
    final currentSong = musicStore.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: musicStore.audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = musicStore.audioPlayer.duration ?? Duration.zero;
              final buffered = musicStore.audioPlayer.bufferedPosition;

              return ProgressBar(
                progress: position,
                total: duration,
                buffered: buffered,
                barHeight: 4.0,
                thumbRadius: 6.0,
                baseBarColor: Colors.grey.withValues(alpha: 0.2),
                progressBarColor: Colors.blueAccent,
                bufferedBarColor: Colors.grey.withValues(alpha: 0.4),
                thumbColor: Colors.blueAccent,
                timeLabelTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Courier',
                ),
                onSeek: (newPosition) {
                  musicStore.audioPlayer.seek(newPosition);
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    color: Colors.black87,
                    onPressed: musicStore.playPrevious,
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
                          margin: const EdgeInsets.symmetric(horizontal: 12.0),
                          width: 24.0,
                          height: 24.0,
                          child: const CircularProgressIndicator(strokeWidth: 3),
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
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    color: Colors.black87,
                    onPressed: musicStore.playNext,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
