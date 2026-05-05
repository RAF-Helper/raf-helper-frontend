import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService api;

  bool _isAuthenticated = false;
  bool _needsEmailVerification = false;
  String? _userEmail;
  int? _pgUserId;

  AuthService({ApiService? apiService})
      : api = apiService ?? ApiService();

  bool get isAuthenticated => _isAuthenticated;
  bool get needsEmailVerification => _needsEmailVerification;
  String? get userEmail => _userEmail;
  int? get pgUserId => _pgUserId;
  User? get firebaseUser => _firebaseAuth.currentUser;

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
      await _syncWithBackend(refreshed);
      return true;
    }
    return false;
  }

  Future<void> _syncWithBackend(User user) async {
    final idToken = await user.getIdToken(true); // force-refresh so token has latest email_verified claim
    if (idToken == null) throw Exception('Не удалось получить токен');

    api.setAuthToken(idToken);

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
    _isAuthenticated = false;
    _needsEmailVerification = false;
    _userEmail = null;
    _pgUserId = null;
    notifyListeners();
  }
}
