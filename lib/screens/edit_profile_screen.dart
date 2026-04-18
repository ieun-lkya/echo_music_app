import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/music_api.dart';
import '../utils/toast_util.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _avatarController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _avatarController = TextEditingController();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('echo_nickname') ?? '';
    final avatar = prefs.getString('echo_avatar') ?? '';
    setState(() {
      _nicknameController.text = nickname;
      _avatarController.text = avatar;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('echo_user_id');
      if (userId == null) {
        if (mounted) {
          ToastUtil.error(context, '用户未登录');
        }
        return;
      }

      final user = {
        'id': userId,
        'nickname': _nicknameController.text.trim(),
        'avatar': _avatarController.text.trim(),
      };

      final result = await MusicApi.updateUserProfile(user);
      if (result != null) {
        await prefs.setString('echo_nickname', _nicknameController.text.trim());
        await prefs.setString('echo_avatar', _avatarController.text.trim());
        if (mounted) {
          ToastUtil.success(context, '保存成功！');
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ToastUtil.error(context, '保存失败');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, '保存失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarController.text.isNotEmpty
                        ? NetworkImage(_avatarController.text)
                        : null,
                    child: _avatarController.text.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blueAccent,
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('修改头像'),
                              content: TextField(
                                controller: _avatarController,
                                decoration: const InputDecoration(
                                  hintText: '输入头像URL',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入昵称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _avatarController,
              decoration: const InputDecoration(
                labelText: '头像URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }
}
