import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../components/comment_sheet.dart';
import '../utils/toast_util.dart';
import 'echo_fm_screen.dart';
import 'sleep_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _musicList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _myPlaylists = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    _loadMusicData();
    _fetchPlaylists();
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
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPlaylists() async {
    final list = await MusicApi.getPlaylists();
    if (mounted) {
      setState(() => _myPlaylists = list);
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

  void _showAddToPlaylistSheet(Map<String, dynamic> music) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '将《${music['title']}》加入歌单',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              if (_myPlaylists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('你还没有创建任何歌单哦'),
                ),
              ..._myPlaylists.map(
                (p) => ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(p['name']),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await MusicApi.addMusicToPlaylist(p['id'], music['id']);
                      if (mounted) {
                        ToastUtil.success(context, '已成功加入歌单！');
                      }
                    } catch (e) {
                      if (mounted) {
                        ToastUtil.error(context, e.toString());
                      }
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('新建歌单...'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreatePlaylistDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌单'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: '输入歌单名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await MusicApi.createPlaylist(nameController.text);
                _fetchPlaylists();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadMusicData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [_buildQuickAccessSection(), _buildBody()],
            ),
          ),
          const PlayerBar(),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAccessCard(
              icon: Icons.radio,
              title: 'Echo FM',
              subtitle: '智能电台',
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EchoFmScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickAccessCard(
              icon: Icons.nightlight,
              title: '助眠模式',
              subtitle: '放松身心',
              gradient: const LinearGradient(
                colors: [Colors.indigo, Colors.purple],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SleepModeScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
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
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showAddToPlaylistSheet(music),
              ),
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
