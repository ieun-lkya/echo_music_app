import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../stores/music_store.dart';
import '../api/music_api.dart';

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
                    GestureDetector(
                      onTap: () {
                        final artist = currentSong['artist'];
                        if (artist != null && artist != '未知歌手') {
                          _showArtistBio(context, artist);
                        }
                      },
                      child: Text(
                        currentSong['artist'] ?? '未知歌手',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                      ),
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

  void _showArtistBio(BuildContext context, String artist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                  const SizedBox(width: 8),
                  Text(
                    'AI 眼中的 $artist',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<String>(
                  future: MusicApi.getArtistBio(artist),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'AI 正在翻阅全网音乐百科...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '翻车了：${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        child: Text(
                          snapshot.data ?? '暂无资料',
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
