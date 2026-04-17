import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../components/comment_sheet.dart';
import 'ai_recommend_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _musicList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMusicData();
  }

  Future<void> _loadMusicData() async {
    setState(() => _isLoading = true);
    try {
      final data = await MusicApi.getMusicList();
      setState(() {
        _musicList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) async {
    if (value.isEmpty) {
      _loadMusicData();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await MusicApi.searchMusic(value);
      if (mounted) {
        setState(() {
          _musicList = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('搜索失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索歌名、歌手...',
                  border: InputBorder.none,
                ),
                onSubmitted: _onSearch,
              )
            : const Text('Echo 音乐库'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadMusicData();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy, color: Colors.blueAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiRecommendScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMusicData,
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

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          '出错了：$_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_musicList.isEmpty) {
      return const Center(child: Text('当前曲库空空如也~'));
    }

    return ListView.builder(
      itemCount: _musicList.length,
      itemBuilder: (context, index) {
        final music = _musicList[index];

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
                icon: const Icon(Icons.comment_outlined),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CommentSheet(music: music),
                  );
                },
              ),
              const Icon(Icons.play_arrow),
            ],
          ),
          onTap: () =>
              context.read<MusicStore>().playPlaylist(_musicList, index),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
