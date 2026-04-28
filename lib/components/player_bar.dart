import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../stores/music_store.dart';
import '../api/music_api.dart';
import '../utils/toast_util.dart';
import 'music_cover.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key});

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  bool _isLiked = false;

  static final Map<String, Future<String?>> _bioCache = {};

  Future<String?> _getArtistBioCached(String artistName) {
    if (!_bioCache.containsKey(artistName)) {
      _bioCache[artistName] = MusicApi.getArtistBio(artistName);
    }
    return _bioCache[artistName]!;
  }

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
              MusicCover(song: currentSong, size: 48, radius: 8),
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
                      onTap: () =>
                          _showArtistBio(context, currentSong['artist']),
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
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.black87,
                    ),
                    onPressed: () => _toggleLike(musicStore, currentSong),
                  ),
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
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
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

  Future<void> _toggleLike(
    MusicStore musicStore,
    Map<String, dynamic> song,
  ) async {
    final musicId = song['id'] is int
        ? song['id']
        : int.parse(song['id'].toString());
    try {
      if (_isLiked) {
        await MusicApi.unlikeMusic(musicId);
      } else {
        await MusicApi.likeMusic(musicId);
      }
      if (mounted) {
        setState(() => _isLiked = !_isLiked);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '操作失败：$e');
      }
    }
  }

  Future<void> _showArtistBio(BuildContext context, String? artistName) async {
    if (artistName == null || artistName.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: FutureBuilder<String?>(
          future: _getArtistBioCached(artistName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text('暂无该歌手的传记信息'));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artistName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
