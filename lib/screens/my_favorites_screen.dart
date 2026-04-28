import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../components/music_cover.dart';
import '../utils/toast_util.dart';

class MyFavoritesScreen extends StatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  State<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends State<MyFavoritesScreen> {
  List<dynamic> _favoritesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final list = await MusicApi.getMyLikes();
      if (mounted) {
        setState(() {
          _favoritesList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '加载失败：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        centerTitle: true,
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

    if (_favoritesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无收藏歌曲',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _favoritesList.length,
      itemBuilder: (context, index) {
        final music = _favoritesList[index];
        return ListTile(
          leading: MusicCover(song: music),
          title: Text(music['title'] ?? '未知歌曲'),
          subtitle: Text(music['artist'] ?? '未知歌手'),
          onTap: () {
            context.read<MusicStore>().playPlaylist(_favoritesList, index);
          },
        );
      },
    );
  }
}
