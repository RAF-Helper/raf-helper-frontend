import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

enum LoginMode { login, register, verifyEmail }

class LoginScreen extends StatefulWidget {
  final LoginMode initialMode;

  const LoginScreen({super.key, this.initialMode = LoginMode.login});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  late LoginMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (!email.endsWith('@bsu.by')) {
      setState(() => _errorMessage = 'Только email @bsu.by разрешены');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Введите пароль');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final auth = context.read<AuthService>();
      if (_mode == LoginMode.register) {
        await auth.register(email, _passwordController.text);
        setState(() {
          _mode = LoginMode.verifyEmail;
          _infoMessage = 'Письмо отправлено на $email. Подтвердите email.';
        });
      } else {
        await auth.login(email, _passwordController.text);
      }
    } catch (e) {
      setState(() => _errorMessage = _formatError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final verified = await context.read<AuthService>().checkEmailVerified();
      if (!verified && mounted) {
        setState(() => _errorMessage = 'Email ещё не подтверждён');
      }
    } catch (e) {
      setState(() => _errorMessage = _formatError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    try {
      await context.read<AuthService>().resendVerificationEmail();
      setState(() => _infoMessage = 'Письмо отправлено повторно');
    } catch (e) {
      setState(() => _errorMessage = _formatError(e.toString()));
    }
  }

  String _formatError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Неверный email или пароль';
    }
    if (raw.contains('user-not-found')) return 'Пользователь не найден';
    if (raw.contains('email-already-in-use')) return 'Email уже зарегистрирован';
    if (raw.contains('weak-password')) return 'Слишком простой пароль';
    if (raw.contains('too-many-requests')) return 'Слишком много попыток, попробуйте позже';
    if (raw.contains('Email не подтверждён')) return 'Email не подтверждён. Проверьте почту.';
    return raw.replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _mode == LoginMode.verifyEmail
                  ? _buildVerifyEmail()
                  : _buildLoginForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final isRegister = _mode == LoginMode.register;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.school, size: 80, color: Color(0xFF0A84FF)),
        const SizedBox(height: 24),
        const Text(
          'RAF Helper',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ассистент для студентов БГУ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email (@bsu.by)',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Пароль',
            prefixIcon: const Icon(Icons.lock_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
          ),
          onSubmitted: (_) => _handleSubmit(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A84FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isRegister ? 'Зарегистрироваться' : 'Войти',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _mode = isRegister ? LoginMode.login : LoginMode.register;
              _errorMessage = null;
              _infoMessage = null;
            });
          },
          child: Text(
            isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться',
            style: const TextStyle(color: Color(0xFF0A84FF)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyEmail() {
    final email = context.read<AuthService>().userEmail ?? _emailController.text;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Color(0xFF0A84FF)),
        const SizedBox(height: 24),
        const Text(
          'Подтвердите email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Письмо отправлено на $email.\nОткройте ссылку из письма и нажмите кнопку ниже.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
        if (_infoMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _infoMessage!,
            style: const TextStyle(color: Colors.greenAccent),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _checkVerification,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A84FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Я подтвердил email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resendEmail,
          child: const Text(
            'Отправить письмо повторно',
            style: TextStyle(color: Color(0xFF0A84FF)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            context.read<AuthService>().logout();
            setState(() {
              _mode = LoginMode.login;
              _errorMessage = null;
              _infoMessage = null;
            });
          },
          child: const Text(
            'Назад к входу',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
