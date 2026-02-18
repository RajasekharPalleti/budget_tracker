import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  String _profileImagePath = '';
  Uint8List? _profileImageBytes; // In-memory bytes (web + mobile)
  bool _isFirstLaunch = true;

  String get username => _username;
  String get profileImagePath => _profileImagePath;
  Uint8List? get profileImageBytes => _profileImageBytes;
  bool get isFirstLaunch => _isFirstLaunch;

  static const String _usernameKey = 'user_name';
  static const String _profileImageKey = 'profile_image_path';
  static const String _profileImageBytesKey = 'profile_image_bytes_b64';
  static const String _firstLaunchKey = 'first_launch';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_usernameKey) ?? '';
    _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    // Restore bytes (works on both web and mobile)
    final b64 = prefs.getString(_profileImageBytesKey);
    if (b64 != null && b64.isNotEmpty) {
      _profileImageBytes = base64Decode(b64);
      _profileImagePath = 'persisted_image'; // sentinel
    } else {
      // Fallback: mobile file path
      _profileImagePath = prefs.getString(_profileImageKey) ?? '';
    }

    notifyListeners();
  }

  Future<void> setUsername(String name) async {
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
    notifyListeners();
  }

  Future<void> setProfileImage(String path) async {
    _profileImagePath = path;
    _profileImageBytes = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
    await prefs.remove(_profileImageBytesKey); // clear any old bytes
    notifyListeners();
  }

  /// Saves image bytes to memory AND persists as Base64 in SharedPreferences.
  /// Works on web (no file system) and mobile alike.
  Future<void> setProfileImageBytes(Uint8List bytes) async {
    _profileImageBytes = bytes;
    _profileImagePath = 'persisted_image'; // non-empty sentinel
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageBytesKey, base64Encode(bytes));
    await prefs.remove(_profileImageKey); // clear old path
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    notifyListeners();
  }
}
