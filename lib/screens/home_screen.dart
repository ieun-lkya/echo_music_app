import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../components/ai_playlist_card.dart';
import 'ai_recommend_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _musicList = [];
  List<dynamic> _aiPlaylists = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        MusicApi.getMusicList(),
        MusicApi.generateAiPlaylists(),
      ]);
      setState(() {
        _musicList = results[0];
        _aiPlaylists = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo 音乐库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy, color: Colors.blueAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiRecommendScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
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

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          '出错了：$_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView(
      children: [
        if (_aiPlaylists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purpleAccent),
                SizedBox(width: 8),
                Text(
                  'AI 智能推荐',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _aiPlaylists.length,
              itemBuilder: (context, index) =>
                  AiPlaylistCard(playlist: _aiPlaylists[index]),
            ),
          ),
        ],
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '全部音乐',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _musicList.length,
          itemBuilder: (context, index) {
            final music = _musicList[index];
            bool isLiked = music['isLiked'] ?? false;

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  music['coverUrl'] ?? 'https://via.placeholder.com/50',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.music_note, size: 50),
                ),
              ),
              title: Text(music['title'] ?? '未知歌曲'),
              subtitle: Text(music['artist'] ?? '未知歌手'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      try {
                        await MusicApi.toggleLike(music['id']);
                        if (mounted) {
                          setState(() {
                            music['isLiked'] = !isLiked;
                          });
                        }
                      } catch (e) {
                        debugPrint('点赞失败：$e');
                      }
                    },
                  ),
                  const Icon(Icons.play_arrow),
                ],
              ),
              onTap: () =>
                  context.read<MusicStore>().playPlaylist(_musicList, index),
            );
          },
        ),
      ],
    );
  }
}
