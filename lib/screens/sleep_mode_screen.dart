import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../utils/toast_util.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({super.key});

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen> {
  List<dynamic> _sleepPlaylist = [];
  bool _isLoading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initSleepMode();
  }

  Future<void> _initSleepMode() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await MusicApi.generateAiPlaylists();
      final sleepPlaylist = playlists.firstWhere(
        (p) =>
            p['basis']?.toString().toLowerCase().contains('sleep') == true ||
            p['name']?.toString().contains('助眠') == true ||
            p['tags']?.toString().toLowerCase().contains('sleep') == true ||
            p['tags']?.toString().contains('助眠') == true,
        orElse: () => playlists.length > 1 ? playlists[1] : {},
      );
      if (mounted) {
        setState(() {
          _sleepPlaylist = List<dynamic>.from(sleepPlaylist['songs'] ?? []);
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

  Future<void> _refreshSleepMode() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await MusicApi.generateAiPlaylists();
      final sleepPlaylist = playlists.firstWhere(
        (p) =>
            p['basis']?.toString().toLowerCase().contains('sleep') == true ||
            p['name']?.toString().contains('助眠') == true ||
            p['tags']?.toString().toLowerCase().contains('sleep') == true ||
            p['tags']?.toString().contains('助眠') == true,
        orElse: () => playlists.length > 1 ? playlists[1] : {},
      );
      if (mounted) {
        setState(() {
          _sleepPlaylist = List<dynamic>.from(sleepPlaylist['songs'] ?? []);
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
    if (index >= 0 && index < _sleepPlaylist.length) {
      setState(() => _currentIndex = index);
      context.read<MusicStore>().playPlaylist(_sleepPlaylist, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: const Text(
          '助眠模式',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshSleepMode,
            tooltip: '换一批',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: const PlayerBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_sleepPlaylist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nightlight, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              '暂无助眠音乐',
              style: TextStyle(fontSize: 18, color: Colors.white70),
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
      itemCount: _sleepPlaylist.length,
      itemBuilder: (context, index) {
        final song = _sleepPlaylist[index];
        final isPlaying = _currentIndex == index;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isPlaying
                ? Colors.blueAccent.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song['coverUrl'] ?? 'https://via.placeholder.com/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ),
                if (isPlaying)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.equalizer,
                        color: Colors.white, size: 24),
                  ),
              ],
            ),
            title: Text(
              song['title'] ?? '未知歌曲',
              style: TextStyle(
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                color: isPlaying ? Colors.blueAccent : Colors.white,
              ),
            ),
            subtitle: Text(
              song['artist'] ?? '未知歌手',
              style: const TextStyle(color: Colors.white60),
            ),
            onTap: () => _playSong(index),
          ),
        );
      },
    );
  }
}
