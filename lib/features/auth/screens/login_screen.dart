import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../progress/application/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'nam@example.com');
  final password = TextEditingController(text: '123456');
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 72,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đăng nhập X-Physics',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    final ok = context.read<AppState>().login(
                      email.text.trim(),
                      password.text,
                    );
                    if (ok) {
                      context.go('/');
                    }
                    setState(
                      () =>
                          error = ok ? null : 'Email hoặc mật khẩu không đúng.',
                    );
                  },
                  child: const Text('Đăng nhập'),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Tạo tài khoản học sinh'),
                ),
                TextButton(
                  onPressed: () {
                    email.text = 'admin@example.com';
                    password.text = '123456';
                  },
                  child: const Text('Dùng tài khoản Admin demo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
