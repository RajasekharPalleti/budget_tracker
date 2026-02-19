import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  String _profileImagePath = '';
  Uint8List? _profileImageBytes; // In-memory bytes (mostly for immediate UI update / web)
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
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString(_usernameKey) ?? '';
      _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

      // 1. Try to load from file path (New Approach)
      final path = prefs.getString(_profileImageKey);
      if (path != null && path.isNotEmpty) {
        if (!kIsWeb) {
           final file = File(path);
           if (await file.exists()) {
             _profileImagePath = path;
             // We don't necessarily need to load _profileImageBytes for mobile, 
             // as the UI uses FileImage(_profileImagePath).
           }
        } else {
           // Web doesn't support dart:io File in the same way, but let's stick to mobile optimization first.
           // On web, we might still rely on bytes/blob if we were supporting it fully.
           // For now, assuming mobile focus for the "slow loading" issue.
        }
      }

      // 2. Legacy Migration (Old Base64 Approach)
      // If we didn't find a valid file path, check for legacy base64 data
      if (_profileImagePath.isEmpty) {
        final b64 = prefs.getString(_profileImageBytesKey);
        if (b64 != null && b64.isNotEmpty) {
          try {
            final bytes = base64Decode(b64);
            // Migrate: Save to file and update prefs
            await setProfileImageBytes(bytes); 
          } catch (e) {
            debugPrint('Error migrating legacy image: $e');
            // Remove corrupted data
            await prefs.remove(_profileImageBytesKey);
          }
        }
      }

    } catch (e) {
      debugPrint('UserProvider loadUserData failed: $e');
      _username = '';
      _isFirstLaunch = true;
      _profileImagePath = '';
      _profileImageBytes = null;
    }
    notifyListeners();
  }

  Future<void> setUsername(String name) async {
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
    notifyListeners();
  }

  // Not used directly anymore, but kept for compatibility if needed. 
  // Prefer setProfileImageBytes for saving new images.
  Future<void> setProfileImage(String path) async {
    _profileImagePath = path;
    _profileImageBytes = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
    await prefs.remove(_profileImageBytesKey); 
    notifyListeners();
  }

  Future<void> setProfileImageBytes(Uint8List bytes) async {
    _profileImageBytes = bytes; // Immediate UI feedback

    try {
      if (!kIsWeb) {
        // Save to file on mobile
        final directory = await getApplicationDocumentsDirectory();
        // Use timestamp to prevent caching issues
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${directory.path}/profile_$timestamp.png';
        final file = File(path);
        await file.writeAsBytes(bytes);

        // Delete old file if it exists
        if (_profileImagePath.isNotEmpty) {
          try {
            final oldFile = File(_profileImagePath);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (e) {
            debugPrint('Error deleting old profile image: $e');
          }
        }

        _profileImagePath = path;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImageKey, path);
        
        // Clear legacy key to free up space
        await prefs.remove(_profileImageBytesKey);
      } else {
        // Web fallback (keep using base64 or ephemeral)
        // If web support is critical, we'd keep the base64 implementation for web only.
        // Assuming the user is on mobile (Android/iOS) based on the "slow loading" report.
        _profileImagePath = 'web_memory_image'; 
      }
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      // Fallback or error handling
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    notifyListeners();
  }
}
