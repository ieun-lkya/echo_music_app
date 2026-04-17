import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../api/user_api.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入账号和密码')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        final userData = await UserApi.login(username, password);
        final token = userData['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('echo_token', token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 登录成功！'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/');
        }
      } else {
        await UserApi.register(username, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('注册成功，请登录!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isLoginMode = true;
            _passwordController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
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
                child: Text(
                  _isLoginMode ? '没有账号？点击注册' : '已有账号？去登录',
                ),
              )
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
