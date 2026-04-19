import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../utils/toast_util.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<dynamic> _aiPlaylists = [];
  final List<dynamic> _librarySongs = [];
  bool _isLoadingAi = false;
  bool _isLoadingLibrary = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAiPlaylists();
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAiPlaylists() async {
    setState(() => _isLoadingAi = true);
    try {
      final playlists = await MusicApi.generateAiPlaylists();
      if (mounted) {
        setState(() {
          _aiPlaylists.clear();
          _aiPlaylists.addAll(playlists);
          _isLoadingAi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAi = false);
        ToastUtil.error(context, '加载 AI 推荐失败：$e');
      }
    }
  }

  Future<void> _loadLibrary() async {
    setState(() => _isLoadingLibrary = true);
    try {
      final songs = await MusicApi.getMusicList();
      if (mounted) {
        setState(() {
          _librarySongs.clear();
          _librarySongs.addAll(songs);
          _isLoadingLibrary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLibrary = false);
        ToastUtil.error(context, '加载曲库失败：$e');
      }
    }
  }

  List<dynamic> get _filteredLibrary {
    if (_searchQuery.isEmpty) return _librarySongs;
    return _librarySongs.where((song) {
      final title = (song['title'] ?? '').toString().toLowerCase();
      final artist = (song['artist'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          artist.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy), text: 'AI 推荐'),
            Tab(icon: Icon(Icons.library_music), text: '曲库'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAiRecommendTab(),
                _buildLibraryTab(),
              ],
            ),
          ),
          const PlayerBar(),
        ],
      ),
    );
  }

  Widget _buildAiRecommendTab() {
    if (_isLoadingAi) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_aiPlaylists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无 AI 推荐',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAiPlaylists,
              icon: const Icon(Icons.refresh),
              label: const Text('获取推荐'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAiPlaylists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _aiPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = _aiPlaylists[index];
          final songs = List<dynamic>.from(playlist['songs'] ?? []);
          final name = playlist['name'] ?? 'AI 推荐歌单';
          final description = playlist['description'] ?? '';
          final tags = playlist['tags'] ?? '';
          final basis = playlist['basis'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: songs.isNotEmpty
                    ? Image.network(
                        songs[0]['coverUrl'] ?? 'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note, size: 50),
                      )
                    : const Icon(Icons.music_note, size: 50),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description.isNotEmpty) Text(description),
                  if (tags.isNotEmpty)
                    Text(
                      '标签：$tags',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (basis.isNotEmpty)
                    Text(
                      '类型：$basis',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${songs.length} 首歌曲',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      ElevatedButton.icon(
                        onPressed: songs.isEmpty
                            ? null
                            : () {
                                context.read<MusicStore>().playPlaylist(songs, 0);
                                ToastUtil.success(context, '开始播放');
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('播放全部'),
                      ),
                    ],
                  ),
                ),
                ...songs.map((song) => ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          song['coverUrl'] ?? 'https://via.placeholder.com/40',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.music_note, size: 40),
                        ),
                      ),
                      title: Text(song['title'] ?? '未知歌曲'),
                      subtitle: Text(song['artist'] ?? '未知歌手'),
                      onTap: () {
                        context.read<MusicStore>().playPlaylist(
                              songs,
                              songs.indexOf(song),
                            );
                      },
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLibraryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索歌曲或歌手...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        if (_isLoadingLibrary)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_filteredLibrary.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? '曲库为空' : '未找到相关歌曲',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLibrary,
              child: ListView.builder(
                itemCount: _filteredLibrary.length,
                itemBuilder: (context, index) {
                  final song = _filteredLibrary[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        song['coverUrl'] ?? 'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note, size: 50),
                      ),
                    ),
                    title: Text(song['title'] ?? '未知歌曲'),
                    subtitle: Text(song['artist'] ?? '未知歌手'),
                    onTap: () {
                      context
                          .read<MusicStore>()
                          .playPlaylist(_filteredLibrary, index);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
