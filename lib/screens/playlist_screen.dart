import 'package:flutter/material.dart';
import '../api/music_api.dart';
import '../components/player_bar.dart';
import 'playlist_detail_screen.dart';
import 'my_favorites_screen.dart';
import '../utils/toast_util.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<dynamic> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final list = await MusicApi.getPlaylists();

      // 为每个歌单获取实际的歌曲数量
      for (var playlist in list) {
        try {
          final musics = await MusicApi.getPlaylistDetail(playlist['id']);
          playlist['musicCount'] = musics.length;
        } catch (e) {
          playlist['musicCount'] = 0;
        }
      }

      if (mounted) {
        setState(() {
          _playlists = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtil.error(context, '加载歌单失败：$e');
      }
    }
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: '输入歌单名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final name = nameController.text.trim();
                Navigator.pop(dialogContext);
                try {
                  await MusicApi.createPlaylist(name);
                  _loadPlaylists();
                  if (mounted) {
                    ToastUtil.success(context, '歌单创建成功！');
                  }
                } catch (e) {
                  if (mounted) {
                    ToastUtil.error(context, '创建失败：$e');
                  }
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(Map<String, dynamic> playlist) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除歌单'),
        content: Text('确定要删除歌单「${playlist['name']}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await MusicApi.deletePlaylist(playlist['id']);
                _loadPlaylists();
                if (mounted) {
                  ToastUtil.success(context, '歌单已删除');
                }
              } catch (e) {
                if (mounted) {
                  ToastUtil.error(context, '删除失败：$e');
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的歌单'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePlaylistDialog,
            tooltip: '新建歌单',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaylists,
            tooltip: '刷新',
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

    return ListView(
      children: [
        _buildFavoritesCard(),
        if (_playlists.isEmpty) _buildEmptyState() else _buildPlaylistsList(),
      ],
    );
  }

  Widget _buildFavoritesCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.redAccent, Colors.pinkAccent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 32),
        ),
        title: const Text(
          '我的收藏',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('我喜欢的音乐', style: TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyFavoritesScreen()),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '还没有歌单',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 创建你的第一个歌单',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreatePlaylistDialog,
              icon: const Icon(Icons.add),
              label: const Text('新建歌单'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.queue_music,
                color: Colors.white,
                size: 32,
              ),
            ),
            title: Text(
              playlist['name'] ?? '未命名歌单',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${playlist['musicCount'] ?? 0} 首歌曲',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _showDeletePlaylistDialog(playlist),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    playlistId: playlist['id'],
                    playlistName: playlist['name'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
