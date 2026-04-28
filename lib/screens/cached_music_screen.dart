import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/music_api.dart';
import '../components/music_cover.dart';
import '../components/player_bar.dart';
import '../stores/music_store.dart';

class CachedMusicScreen extends StatefulWidget {
  const CachedMusicScreen({super.key});

  @override
  State<CachedMusicScreen> createState() => _CachedMusicScreenState();
}

class _CachedMusicScreenState extends State<CachedMusicScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await MusicApi.getCachedMusicList();
    if (!mounted) return;

    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('缓存歌曲'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSongs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          const PlayerBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.offline_pin_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '还没有缓存歌曲',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return ListTile(
          leading: MusicCover(song: song),
          title: Text(song['title'] ?? '未知歌曲'),
          subtitle: Text(song['artist'] ?? '未知歌手'),
          trailing: const Icon(Icons.offline_pin),
          onTap: () {
            context.read<MusicStore>().playPlaylist(_songs, index);
          },
        );
      },
    );
  }
}
