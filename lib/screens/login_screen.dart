import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../api/user_api.dart';
import '../utils/toast_util.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  void _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ToastUtil.error(context, '请输入账号和密码');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        final userData = await UserApi.login(username, password);
        final token = userData['token'];
        final user = userData['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('echo_token', token);
        await prefs.setString('echo_username', username);
        if (user != null) {
          if (user['id'] != null) {
            await prefs.setInt('echo_user_id', user['id']);
          }
          if (user['nickname'] != null) {
            await prefs.setString('echo_nickname', user['nickname']);
          }
          if (user['avatar'] != null) {
            await prefs.setString('echo_avatar', user['avatar']);
          }
        }
        if (mounted) {
          ToastUtil.success(context, '🎉 登录成功！');
          context.go('/');
        }
      } else {
        await UserApi.register(username, password);
        if (mounted) {
          ToastUtil.success(context, '注册成功，请登录!');
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoginMode ? '欢迎回到 Echo' : '加入 Echo 音乐',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '账号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _isLoginMode ? '登 录' : '注 册',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(_isLoginMode ? '没有账号？点击注册' : '已有账号？去登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
