import 'package:flutter/material.dart';
import '../api/music_api.dart';
import '../utils/toast_util.dart';

class CommentSheet extends StatefulWidget {
  final Map<String, dynamic> music;
  const CommentSheet({super.key, required this.music});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  final Set<int> _likedComments = {};

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final musicId = widget.music['id'];
    final data = await MusicApi.getComments(
      musicId is int ? musicId : int.parse(musicId.toString()),
    );
    setState(() {
      _comments = data;
      _isLoading = false;
    });
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      final musicId = widget.music['id'];
      await MusicApi.addComment(
        musicId is int ? musicId : int.parse(musicId.toString()),
        text,
      );
      if (mounted) {
        _commentController.clear();
        _fetchComments();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, e.toString());
      }
    }
  }

  Future<void> _toggleLike(int commentId, int index) async {
    try {
      if (_likedComments.contains(commentId)) {
        await MusicApi.likeComment(commentId);
        setState(() {
          _likedComments.add(commentId);
          _comments[index]['likeCount'] =
              (_comments[index]['likeCount'] ?? 0) + 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '操作失败：$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '评论 (${_comments.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      final commentId = c['id'] ?? 0;
                      final isLiked = _likedComments.contains(commentId);
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          c['username'] ?? '匿名用户',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(c['content'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _toggleLike(commentId, index),
                                ),
                                Text(
                                  '${c['likeCount'] ?? 0}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c['createTime'] != null &&
                                      c['createTime'].toString().length >= 10
                                  ? c['createTime'].toString().substring(5, 10)
                                  : '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '随乐而起，抒发感悟...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
