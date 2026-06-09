import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService api;

  bool _isAuthenticated = false;
  bool _isInitializing = true;
  bool _needsEmailVerification = false;
  String? _userEmail;
  int? _pgUserId;

  AuthService({ApiService? apiService})
      : api = apiService ?? ApiService() {
    // Interceptor будет перед каждым запросом получать актуальный токен.
    // Firebase SDK кеширует токен и обновляет только когда он протух.
    api.setTokenProvider((forceRefresh) async {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    });
    _tryRestoreSession();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;
  bool get needsEmailVerification => _needsEmailVerification;
  String? get userEmail => _userEmail;
  int? get pgUserId => _pgUserId;
  User? get firebaseUser => _firebaseAuth.currentUser;

  /// Проверяет, есть ли сохранённый Firebase user, и восстанавливает сессию.
  Future<void> _tryRestoreSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || !user.emailVerified) return;
      // Force-refresh чтобы получить актуальный токен с email_verified claim
      await user.getIdToken(true);
      await _syncWithBackend(user);
    } catch (e) {
      debugPrint('Session restore failed: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    if (!email.endsWith('@bsu.by')) {
      throw Exception('Только email @bsu.by разрешены');
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Ошибка авторизации');

    if (!user.emailVerified) {
      _userEmail = email;
      _needsEmailVerification = true;
      _isAuthenticated = false;
      notifyListeners();
      throw Exception('Email не подтверждён. Проверьте почту.');
    }

    // Force-refresh для получения актуального email_verified claim
    await user.getIdToken(true);
    await _syncWithBackend(user);
  }

  Future<void> register(String email, String password) async {
    if (!email.endsWith('@bsu.by')) {
      throw Exception('Только email @bsu.by разрешены');
    }

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Ошибка регистрации');

    await user.sendEmailVerification();

    _userEmail = email;
    _needsEmailVerification = true;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshed = _firebaseAuth.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      _needsEmailVerification = false;
      await refreshed.getIdToken(true);
      await _syncWithBackend(refreshed);
      return true;
    }
    return false;
  }

  /// Синхронизирует Firebase user с PostgreSQL на бэкенде.
  /// Токен теперь берётся автоматически через interceptor.
  Future<void> _syncWithBackend(User user) async {
    final userData = await api.syncUser();
    _pgUserId = userData['id'];
    _userEmail = user.email;
    _needsEmailVerification = false;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    api.clearAuthToken();
    _isAuthenticated = false;
    _needsEmailVerification = false;
    _userEmail = null;
    _pgUserId = null;
    notifyListeners();
  }
}
