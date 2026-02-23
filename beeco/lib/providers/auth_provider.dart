import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class User {
  final String username;
  final DateTime loginTime;
  User({required this.username, required this.loginTime});
}

class AuthNotifier extends StateNotifier<AuthStatus> {
  User? _currentUser;
  String? _rememberedUsername;

  AuthNotifier() : super(AuthStatus.loading) {
    _checkAuthStatus();
  }

  User? get currentUser => _currentUser;
  String? get rememberedUsername => _rememberedUsername;

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final savedUsername = prefs.getString('saved_username');
    _rememberedUsername = savedUsername;
    
    if (isLoggedIn) {
      final username = prefs.getString('current_username') ?? 'hcc';
      _currentUser = User(username: username, loginTime: DateTime.now());
      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    final validAccounts = {'hcc': '555'};
    
    if (validAccounts[username] == password) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('current_username', username);
      
      if (rememberMe) {
        await prefs.setString('saved_username', username);
      } else {
        await prefs.remove('saved_username');
      }
      
      _currentUser = User(username: username, loginTime: DateTime.now());
      _rememberedUsername = rememberMe ? username : null;
      state = AuthStatus.authenticated;
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_username');
    _currentUser = null;
    state = AuthStatus.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) => AuthNotifier());
