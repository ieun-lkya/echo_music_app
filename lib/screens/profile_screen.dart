import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../utils/toast_util.dart';
import 'play_history_screen.dart';
import 'edit_profile_screen.dart';
import 'message_list_screen.dart';
import 'user_search_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  String _nickname = '';
  String _avatar = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('echo_username') ?? '用户';
    final nickname = prefs.getString('echo_nickname') ?? '';
    final avatar = prefs.getString('echo_avatar') ?? '';
    setState(() {
      _username = username;
      _nickname = nickname;
      _avatar = avatar;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('echo_token');
      await prefs.remove('echo_username');
      await prefs.remove('echo_user_id');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildHeader(),
                const Divider(height: 1),
                _buildMenuSection(),
                const Divider(height: 1),
                _buildLogoutButton(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
        if (result == true) {
          _loadUserInfo();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: _avatar.isNotEmpty
                  ? NetworkImage(_avatar)
                  : null,
              backgroundColor: Colors.blueAccent,
              child: _avatar.isEmpty
                  ? Text(
                      _nickname.isNotEmpty
                          ? _nickname[0].toUpperCase()
                          : (_username.isNotEmpty
                                ? _username[0].toUpperCase()
                                : 'U'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nickname.isNotEmpty ? _nickname : _username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Echo Music 用户',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.history,
          title: '播放历史',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayHistoryScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.person_outline,
          title: '编辑资料',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            if (result == true) {
              _loadUserInfo();
            }
          },
        ),
        _buildMenuItem(
          icon: Icons.message_outlined,
          title: '我的消息',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessageListScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.people_outline,
          title: '搜索用户',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.settings_outlined,
          title: '设置',
          onTap: () {
            ToastUtil.info(context, '设置功能开发中...');
          },
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: '关于',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Echo Music',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.music_note, size: 48),
              children: const [Text('一个基于 Flutter + Spring Boot 的音乐推荐系统')],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('退出登录', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
