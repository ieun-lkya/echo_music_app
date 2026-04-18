import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/music_api.dart';
import '../utils/toast_util.dart';
import 'chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<dynamic> _contacts = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('echo_user_id');

    if (_currentUserId == null) {
      if (mounted) {
        ToastUtil.error(context, '用户未登录');
      }
      return;
    }

    try {
      final contacts = await MusicApi.getRecentContacts(_currentUserId!);
      if (mounted) {
        setState(() {
          _contacts = contacts;
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

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      final date = time is DateTime ? time : DateTime.parse(time.toString());
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return '昨天';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}天前';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无消息',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final item = _contacts[index];
                final contact = item['contact'];
                final lastMessage = item['lastMessage'] ?? '';
                final lastTime = item['lastTime'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        contact['avatar'] != null &&
                            contact['avatar'].isNotEmpty
                        ? NetworkImage(contact['avatar'])
                        : null,
                    child:
                        contact['avatar'] == null || contact['avatar'].isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    contact['nickname'] ?? contact['username'] ?? '未知用户',
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(_formatTime(lastTime)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          targetUserId: contact['id'],
                          targetUserName:
                              contact['nickname'] ??
                              contact['username'] ??
                              '用户',
                        ),
                      ),
                    ).then((_) => _loadContacts());
                  },
                );
              },
            ),
    );
  }
}
