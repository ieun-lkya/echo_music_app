import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/music_api.dart';
import '../stores/music_store.dart';
import '../components/player_bar.dart';
import '../utils/toast_util.dart';

class AiRecommendScreen extends StatefulWidget {
  const AiRecommendScreen({super.key});

  @override
  State<AiRecommendScreen> createState() => _AiRecommendScreenState();
}

class _AiRecommendScreenState extends State<AiRecommendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 智能推荐'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: '对话推荐'),
            Tab(icon: Icon(Icons.auto_awesome), text: '量子歌单'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_ChatRecommendTab(), _QuantumPlaylistTab()],
            ),
          ),
          const PlayerBar(),
        ],
      ),
    );
  }
}

class _ChatRecommendTab extends StatefulWidget {
  const _ChatRecommendTab();

  @override
  State<_ChatRecommendTab> createState() => _ChatRecommendTabState();
}

class _ChatRecommendTabState extends State<_ChatRecommendTab> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });

    try {
      final result = await MusicApi.aiRecommend(message);

      if (result.isNotEmpty) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'content': '为你推荐 ${result.length} 首歌曲',
            'songs': result,
          });
        });
      } else {
        setState(() {
          _messages.add({'role': 'ai', 'content': '抱歉，没有找到合适的音乐推荐'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': '出错了：$e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    _messageController.clear();
  }

  void _showAddToPlaylistDialog(List<dynamic> songs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddToPlaylistSheet(songs: songs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              size: 80,
              color: Colors.blueAccent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '告诉我你想听什么类型的音乐',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '例如：伤感的歌曲、适合运动的音乐',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['role'] == 'user';
        return _buildMessageBubble(message, isUser);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (message['songs'] != null) ...[
                    const SizedBox(height: 12),
                    _buildSongList(message['songs'] as List, isUser),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongList(List<dynamic> songs, bool isUser) {
    return Column(
      children: [
        ...songs.map((song) => _buildSongItem(song, isUser)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<MusicStore>().playPlaylist(songs, 0);
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('播放全部'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isUser ? Colors.white : Colors.blueAccent,
                  side: BorderSide(
                    color: isUser ? Colors.white : Colors.blueAccent,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddToPlaylistDialog(songs),
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('添加到歌单'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isUser ? Colors.white : Colors.blueAccent,
                  side: BorderSide(
                    color: isUser ? Colors.white : Colors.blueAccent,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSongItem(Map<String, dynamic> song, bool isUser) {
    return InkWell(
      onTap: () {
        final idx = _messages
            .where((m) => m['songs'] != null)
            .expand((m) => m['songs'] as List)
            .toList()
            .indexOf(song);
        if (idx >= 0) {
          final allSongs = _messages
              .where((m) => m['songs'] != null)
              .expand((m) => m['songs'] as List)
              .toList();
          context.read<MusicStore>().playPlaylist(allSongs, idx);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                song['coverUrl'] ?? 'https://via.placeholder.com/48',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? '未知歌曲',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song['artist'] ?? '未知歌手',
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: isUser ? Colors.white70 : Colors.grey[600],
                size: 20,
              ),
              onPressed: () async {
                try {
                  await MusicApi.likeMusic(song['id']);
                  if (mounted) {
                    ToastUtil.success(context, '已收藏');
                  }
                } catch (e) {
                  if (mounted) {
                    ToastUtil.error(context, '收藏失败：$e');
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.playlist_add,
                color: isUser ? Colors.white70 : Colors.blueAccent,
                size: 20,
              ),
              onPressed: () => _showAddSingleToPlaylistDialog(song),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSingleToPlaylistDialog(Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddSingleToPlaylistSheet(song: song),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '告诉我你想听什么类型的音乐...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class _QuantumPlaylistTab extends StatefulWidget {
  const _QuantumPlaylistTab();

  @override
  State<_QuantumPlaylistTab> createState() => _QuantumPlaylistTabState();
}

class _QuantumPlaylistTabState extends State<_QuantumPlaylistTab>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _quantumPlaylists = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadQuantumPlaylists();
  }

  Future<void> _loadQuantumPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await MusicApi.generateAiPlaylists();
      if (mounted) {
        setState(() {
          _quantumPlaylists = playlists;
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

  void _playPlaylist(List<dynamic> songs) {
    if (songs.isNotEmpty) {
      context.read<MusicStore>().playPlaylist(songs, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quantumPlaylists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.blueAccent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无量子歌单',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuantumPlaylists,
              icon: const Icon(Icons.refresh),
              label: const Text('生成歌单'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuantumPlaylists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quantumPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = _quantumPlaylists[index];
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
                        songs[0]['coverUrl'] ??
                            'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note, size: 50),
                      )
                    : const Icon(Icons.music_note, size: 50),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                            : () => _playPlaylist(songs),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('播放全部'),
                      ),
                    ],
                  ),
                ),
                ...songs.map(
                  (song) => ListTile(
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddSingleToPlaylistSheet extends StatefulWidget {
  final Map<String, dynamic> song;

  const _AddSingleToPlaylistSheet({required this.song});

  @override
  State<_AddSingleToPlaylistSheet> createState() =>
      _AddSingleToPlaylistSheetState();
}

class _AddSingleToPlaylistSheetState extends State<_AddSingleToPlaylistSheet> {
  List<dynamic> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final list = await MusicApi.getPlaylists();
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

  Future<void> _addToPlaylist(int playlistId) async {
    try {
      await MusicApi.addMusicToPlaylist(playlistId, widget.song['id']);
      if (mounted) {
        Navigator.pop(context);
        ToastUtil.success(context, '已添加到歌单');
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '添加失败：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  widget.song['coverUrl'] ?? 'https://via.placeholder.com/40',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.music_note, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song['title'] ?? '未知歌曲',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.song['artist'] ?? '未知歌手',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            '选择歌单',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_playlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.queue_music, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('还没有歌单', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.queue_music, color: Colors.white),
                  ),
                  title: Text(playlist['name'] ?? '未命名歌单'),
                  subtitle: Text('${playlist['musicCount'] ?? 0} 首歌曲'),
                  onTap: () => _addToPlaylist(playlist['id']),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddToPlaylistSheet extends StatefulWidget {
  final List<dynamic> songs;

  const _AddToPlaylistSheet({required this.songs});

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  List<dynamic> _playlists = [];
  bool _isLoading = true;
  final Set<int> _selectedSongIndices = {};

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final list = await MusicApi.getPlaylists();
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

  Future<void> _addToPlaylist(int playlistId) async {
    final songsToAdd = _selectedSongIndices.isEmpty
        ? widget.songs
        : widget.songs
              .asMap()
              .entries
              .where((entry) => _selectedSongIndices.contains(entry.key))
              .map((entry) => entry.value)
              .toList();

    int successCount = 0;
    for (var song in songsToAdd) {
      try {
        await MusicApi.addMusicToPlaylist(playlistId, song['id']);
        successCount++;
      } catch (e) {
        debugPrint('添加失败: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
      if (successCount > 0) {
        ToastUtil.success(context, '成功添加 $successCount 首歌曲到歌单');
      } else {
        ToastUtil.error(context, '添加失败');
      }
    }
  }

  void _showSelectSongsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择要添加的歌曲'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                final song = widget.songs[index];
                final isSelected = _selectedSongIndices.contains(index);
                return CheckboxListTile(
                  title: Text(song['title'] ?? '未知歌曲'),
                  subtitle: Text(song['artist'] ?? '未知歌手'),
                  value: isSelected,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        _selectedSongIndices.add(index);
                      } else {
                        _selectedSongIndices.remove(index);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '添加到歌单',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.songs.length > 1)
                TextButton.icon(
                  onPressed: _showSelectSongsDialog,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: Text(
                    _selectedSongIndices.isEmpty
                        ? '选择歌曲'
                        : '已选 ${_selectedSongIndices.length}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_playlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.queue_music, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('还没有歌单', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.queue_music, color: Colors.white),
                  ),
                  title: Text(playlist['name'] ?? '未命名歌单'),
                  subtitle: Text('${playlist['musicCount'] ?? 0} 首歌曲'),
                  onTap: () => _addToPlaylist(playlist['id']),
                );
              },
            ),
        ],
      ),
    );
  }
}
