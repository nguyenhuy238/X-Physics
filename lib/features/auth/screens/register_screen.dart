import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../progress/application/app_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, String> _localFieldErrors = const {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fieldErrors = {...state.authFieldErrors, ..._localFieldErrors};
    final showGeneralError = state.errorMessage != null && fieldErrors.isEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại đăng nhập',
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.science_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tạo tài khoản',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bắt đầu lưu tiến độ, xu và huy hiệu học tập của bạn.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: name,
                    label: 'Họ tên',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    enabled: !state.isBusy,
                    errorText: fieldErrors['name'],
                    onChanged: (_) => _clearFieldError(context, 'name'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: email,
                    label: 'Email',
                    hintText: 'name@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !state.isBusy,
                    errorText: fieldErrors['email'],
                    onChanged: (_) => _clearFieldError(context, 'email'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: password,
                    label: 'Mật khẩu',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    enabled: !state.isBusy,
                    errorText: fieldErrors['password'],
                    onChanged: (_) => _clearFieldError(context, 'password'),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: confirmPassword,
                    label: 'Xác nhận mật khẩu',
                    prefixIcon: Icons.verified_user_outlined,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(context),
                    enabled: !state.isBusy,
                    errorText: fieldErrors['confirmPassword'],
                    onChanged: (_) =>
                        _clearFieldError(context, 'confirmPassword'),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  if (showGeneralError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: .20),
                        ),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: state.isBusy ? null : () => _submit(context),
                    icon: state.isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(state.isBusy ? 'Đang tạo...' : 'Bắt đầu học'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isBusy ? null : () => context.go('/login'),
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (context.read<AppState>().isBusy) {
      return;
    }
    final validationErrors = _validateFields();
    if (validationErrors.isNotEmpty) {
      context.read<AppState>().clearAuthErrors();
      setState(() => _localFieldErrors = validationErrors);
      return;
    }
    setState(() => _localFieldErrors = const {});
    final ok = await context.read<AppState>().registerWithConfirmation(
      name.text.trim(),
      email.text.trim(),
      password.text,
      confirmPassword.text,
    );
    if (ok && context.mounted) {
      context.go('/');
    }
  }

  Map<String, String> _validateFields() {
    final errors = <String, String>{};
    final trimmedName = name.text.trim();
    final trimmedEmail = email.text.trim();
    if (trimmedName.isEmpty) {
      errors['name'] = 'Vui lòng nhập họ tên.';
    } else if (trimmedName.length > 120) {
      errors['name'] = 'Họ tên không được vượt quá 120 ký tự.';
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (trimmedEmail.isEmpty) {
      errors['email'] = 'Vui lòng nhập email.';
    } else if (!emailRegex.hasMatch(trimmedEmail)) {
      errors['email'] = 'Email không đúng định dạng.';
    } else if (trimmedEmail.length > 180) {
      errors['email'] = 'Email không được vượt quá 180 ký tự.';
    }

    if (password.text.length < 6) {
      errors['password'] = 'Mật khẩu phải có ít nhất 6 ký tự.';
    } else if (password.text.length > 72) {
      errors['password'] = 'Mật khẩu không được vượt quá 72 ký tự.';
    }

    if (confirmPassword.text.isEmpty) {
      errors['confirmPassword'] = 'Vui lòng xác nhận mật khẩu.';
    } else if (confirmPassword.text != password.text) {
      errors['confirmPassword'] = 'Mật khẩu xác nhận không khớp.';
    }
    return errors;
  }

  void _clearFieldError(BuildContext context, String field) {
    if (_localFieldErrors.containsKey(field)) {
      final next = Map<String, String>.from(_localFieldErrors)..remove(field);
      setState(() => _localFieldErrors = next);
    }
    final appState = context.read<AppState>();
    if (appState.authFieldErrors.isNotEmpty || appState.errorMessage != null) {
      appState.clearAuthErrors();
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }
}
