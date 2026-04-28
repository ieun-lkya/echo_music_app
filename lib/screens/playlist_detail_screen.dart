import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../components/music_cover.dart';
import '../utils/toast_util.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<dynamic> _musics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylistDetail();
  }

  Future<void> _loadPlaylistDetail() async {
    setState(() => _isLoading = true);
    try {
      final musics = await MusicApi.getPlaylistDetail(widget.playlistId);
      if (mounted) {
        setState(() {
          _musics = musics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtil.error(context, '加载失败：$e');
      }
    }
  }

  Future<void> _removeMusic(int musicId) async {
    try {
      await MusicApi.deleteMusicFromPlaylist(widget.playlistId, musicId);
      if (mounted) {
        _loadPlaylistDetail();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已从歌单中移除')));
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '移除失败：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaylistDetail,
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

    if (_musics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '歌单里还没有歌曲',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _musics.length,
      itemBuilder: (context, index) {
        final music = _musics[index];
        return ListTile(
          leading: MusicCover(song: music),
          title: Text(music['title'] ?? '未知歌曲'),
          subtitle: Text(music['artist'] ?? '未知歌手'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _showRemoveDialog(music),
          ),
          onTap: () => context.read<MusicStore>().playPlaylist(_musics, index),
        );
      },
    );
  }

  void _showRemoveDialog(Map<String, dynamic> music) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除歌曲'),
        content: Text('确定要将《${music['title']}》从歌单中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMusic(music['id']);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
