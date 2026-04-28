import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../components/music_cover.dart';
import '../utils/toast_util.dart';

class EchoFmScreen extends StatefulWidget {
  const EchoFmScreen({super.key});

  @override
  State<EchoFmScreen> createState() => _EchoFmScreenState();
}

class _EchoFmScreenState extends State<EchoFmScreen> {
  List<dynamic> _fmPlaylist = [];
  bool _isLoading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initFm();
  }

  Future<void> _initFm() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await MusicApi.generateAiPlaylists();
      final fmPlaylist = playlists.firstWhere(
        (p) => p['basis']?.toString().toLowerCase().contains('fm') == true ||
            p['name']?.toString().toLowerCase().contains('fm') == true ||
            p['tags']?.toString().toLowerCase().contains('fm') == true,
        orElse: () => playlists.isNotEmpty ? playlists[0] : {},
      );
      if (mounted) {
        setState(() {
          _fmPlaylist = List<dynamic>.from(fmPlaylist['songs'] ?? []);
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

  Future<void> _refreshFm() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await MusicApi.generateAiPlaylists();
      final fmPlaylist = playlists.firstWhere(
        (p) => p['basis']?.toString().toLowerCase().contains('fm') == true ||
            p['name']?.toString().toLowerCase().contains('fm') == true ||
            p['tags']?.toString().toLowerCase().contains('fm') == true,
        orElse: () => playlists.isNotEmpty ? playlists[0] : {},
      );
      if (mounted) {
        setState(() {
          _fmPlaylist = List<dynamic>.from(fmPlaylist['songs'] ?? []);
          _currentIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtil.error(context, '刷新失败：$e');
      }
    }
  }

  void _playSong(int index) {
    if (index >= 0 && index < _fmPlaylist.length) {
      setState(() => _currentIndex = index);
      context.read<MusicStore>().playPlaylist(_fmPlaylist, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo FM'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshFm,
            tooltip: '换一批',
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

    if (_fmPlaylist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radio, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无 FM 推荐',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击刷新按钮获取 AI 推荐',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _fmPlaylist.length,
      itemBuilder: (context, index) {
        final song = _fmPlaylist[index];
        final isPlaying = _currentIndex == index;

        return ListTile(
          leading: Stack(
            alignment: Alignment.center,
            children: [
              MusicCover(song: song),
              if (isPlaying)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.equalizer, color: Colors.white, size: 24),
                ),
            ],
          ),
          title: Text(
            song['title'] ?? '未知歌曲',
            style: TextStyle(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying ? Colors.blueAccent : null,
            ),
          ),
          subtitle: Text(song['artist'] ?? '未知歌手'),
          onTap: () => _playSong(index),
        );
      },
    );
  }
}
