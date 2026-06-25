import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _isRegister = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (_phoneCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = '请输入手机号和密码');
      return;
    }

    try {
      if (_isRegister) {
        if (_nicknameCtrl.text.trim().isEmpty) {
          setState(() => _error = '请输入昵称');
          return;
        }
        await widget.authService.register(
          nickname: _nicknameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await widget.authService.login(
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZhiJianTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Text('🏋️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text('智健',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ZhiJianTheme.text)),
                const SizedBox(height: 4),
                const Text('AI 驱动 · 见证每一次蜕变',
                    style: TextStyle(fontSize: 14, color: ZhiJianTheme.textSecondary)),
                const SizedBox(height: 48),

                // Nickname (register only)
                if (_isRegister) ...[
                  TextField(
                    controller: _nicknameCtrl,
                    decoration: _inputDecoration('昵称', Icons.person),
                    style: const TextStyle(color: ZhiJianTheme.text),
                  ),
                  const SizedBox(height: 16),
                ],

                // Phone
                TextField(
                  controller: _phoneCtrl,
                  decoration: _inputDecoration('手机号', Icons.phone_android),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: ZhiJianTheme.text),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordCtrl,
                  decoration: _inputDecoration('密码', Icons.lock),
                  obscureText: true,
                  style: const TextStyle(color: ZhiJianTheme.text),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: ZhiJianTheme.error, fontSize: 14)),
                ],

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.authService.isLoading ? null : _submit,
                    child: widget.authService.isLoading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isRegister ? '注册' : '登录',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle
                TextButton(
                  onPressed: () => setState(() {
                    _isRegister = !_isRegister;
                    _error = null;
                  }),
                  child: Text(
                    _isRegister ? '已有账号？去登录' : '没有账号？去注册',
                    style: const TextStyle(color: ZhiJianTheme.primary),
                  ),
                ),

                const SizedBox(height: 32),

                // Skip login (dev mode)
                TextButton(
                  onPressed: () async {
                    // Quick dev login with test account
                    try {
                      await widget.authService.login(phone: '13800000001', password: '123456');
                    } catch (_) {
                      await widget.authService.register(
                          nickname: '健身达人', phone: '13800000001', password: '123456');
                    }
                  },
                  child: const Text('🚀 快速体验（免注册）',
                      style: TextStyle(color: ZhiJianTheme.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ZhiJianTheme.textSecondary),
      prefixIcon: Icon(icon, color: ZhiJianTheme.textSecondary),
      filled: true,
      fillColor: ZhiJianTheme.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ZhiJianTheme.primary),
      ),
    );
  }
}
