import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/music_api.dart';
import '../utils/toast_util.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isMutual = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('echo_user_id');

    if (_currentUserId == null) {
      if (mounted) {
        ToastUtil.error(context, '用户未登录');
      }
      return;
    }

    try {
      final result = await MusicApi.getUserProfile(
        widget.userId,
        _currentUserId!,
      );
      if (result != null && mounted) {
        setState(() {
          _userData = result['user'];
          _isFollowing = result['isFollowing'] ?? false;
          _isMutual = result['isMutual'] ?? false;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ToastUtil.error(context, '获取用户信息失败');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '加载失败：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null) return;

    try {
      if (_isFollowing) {
        await MusicApi.unfollowUser(_currentUserId!, widget.userId);
        if (mounted) {
          ToastUtil.success(context, '已取消关注');
        }
      } else {
        await MusicApi.followUser(_currentUserId!, widget.userId);
        if (mounted) {
          ToastUtil.success(context, '关注成功');
        }
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户资料'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
          ? const Center(child: Text('用户不存在'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundImage:
                _userData!['avatar'] != null && _userData!['avatar'].isNotEmpty
                ? NetworkImage(_userData!['avatar'])
                : null,
            child: _userData!['avatar'] == null || _userData!['avatar'].isEmpty
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _userData!['nickname'] ?? _userData!['username'] ?? '未知用户',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '@${_userData!['username'] ?? ''}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 24),
        if (_currentUserId != widget.userId) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _toggleFollow,
                icon: Icon(
                  _isFollowing ? Icons.person_remove : Icons.person_add,
                ),
                label: Text(_isFollowing ? '取消关注' : '关注'),
                style: FilledButton.styleFrom(
                  backgroundColor: _isFollowing
                      ? Colors.grey
                      : Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              if (_isMutual)
                const Chip(label: Text('互相关注'), backgroundColor: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      targetUserId: widget.userId,
                      targetUserName:
                          _userData!['nickname'] ??
                          _userData!['username'] ??
                          '用户',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('发消息'),
            ),
          ),
        ],
      ],
    );
  }
}
