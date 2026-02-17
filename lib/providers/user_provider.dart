import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  bool _isFirstLaunch = true;

  String get username => _username;
  bool get isFirstLaunch => _isFirstLaunch;

  static const String _usernameKey = 'user_name';
  static const String _firstLaunchKey = 'first_launch';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_usernameKey) ?? '';
    _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    notifyListeners();
  }

  Future<void> setUsername(String name) async {
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    notifyListeners();
  }
}
