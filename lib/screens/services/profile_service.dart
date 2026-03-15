import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../models/profile.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;
  late SharedPreferences _prefs;

  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 🔑 Get cache key for user
  String _getCacheKey(String userId) => 'profile_$userId';

  /// 📥 Load profile with offline support
  Future<Profile?> loadProfile(String userId) async {
    await initialize();

    try {
      final cachedProfile = _loadProfileFromCache(userId);

      try {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .single();

        if (response != null) {
          final profile = Profile.fromJson(response as Map<String, dynamic>);
          await _saveProfileToCache(userId, profile);
          return profile;
        }
      } catch (e) {
        print('Supabase fetch failed: $e');
      }

      return cachedProfile;
    } catch (e) {
      print('Error loading profile: $e');
      return null;
    }
  }

  /// 💾 Save profile to Supabase
  Future<Profile?> saveProfile(Profile profile) async {
    await initialize();

    try {
      await _supabase.from('profiles').update({
        'full_name': profile.fullName,
        'phone': profile.phone,
        'address': profile.address,
        'city': profile.city,
        'pincode': profile.pincode,
        'avatar_url': profile.avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', profile.userId);

      await _saveProfileToCache(profile.userId, profile);

      return profile;
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  /// 🗑️ Clear profile cache
  Future<void> clearProfileCache(String userId) async {
    await initialize();
    await _prefs.remove(_getCacheKey(userId));
  }

  /// 📦 Load profile from cache
  Profile? _loadProfileFromCache(String userId) {
    try {
      final cached = _prefs.getString(_getCacheKey(userId));
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return Profile.fromJson(json);
      }
    } catch (e) {
      print('Error loading cache: $e');
    }
    return null;
  }

  /// 📦 Save profile to cache
  Future<void> _saveProfileToCache(String userId, Profile profile) async {
    try {
      final json = jsonEncode(profile.toJson());
      await _prefs.setString(_getCacheKey(userId), json);
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  /// 🖼️ Convert image file to base64
  static String encodeImageToBase64(List<int> imageBytes) {
    return 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
  }

  /// 🖼️ Decode base64 image
  static List<int> decodeBase64Image(String base64String) {
    final base64 = base64String.replaceAll('data:image/jpeg;base64,', '');
    return base64Decode(base64);
  }

  /// 🖼️ Upload profile image to Supabase Storage
  Future<String?> uploadProfileImage(
      String userId, List<int> imageBytes) async {
    try {
      const bucket = 'profile_images';
      final path =
          'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final fileData = Uint8List.fromList(imageBytes);

      await _supabase.storage.from(bucket).uploadBinary(
            path,
            fileData,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Failed to upload profile image: $e');
      return null;
    }
  }

  /// 🗑️ Remove image from Supabase Storage
  Future<void> removeProfileImageFromStorage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      final regex = RegExp(r'storage/v1/object/public/([^/]+)/(.+)');
      final match = regex.firstMatch(imageUrl);
      if (match == null) return;

      final bucket = match.group(1);
      final path = match.group(2);

      if (bucket == null || path == null) return;

      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      print('Failed to remove profile image: $e');
    }
  }
}