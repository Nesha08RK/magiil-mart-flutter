import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

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
  /// 1. Load cache first (instant UI)
  /// 2. Fetch from Supabase (background sync)
  /// 3. Update cache if successful
  Future<Profile?> loadProfile(String userId) async {
    await initialize();
    
    try {
      // Step 1: Try to load from cache (instant)
      final cachedProfile = _loadProfileFromCache(userId);
      
      // Step 2: Fetch from Supabase (don't block UI if fails)
      try {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .single();

        if (response != null) {
          final profile = Profile.fromJson(response as Map<String, dynamic>);
          
          // Step 3: Update cache with fresh data
          await _saveProfileToCache(userId, profile);
          
          return profile;
        }
      } catch (e) {
        // Supabase failed, but we have cached data or will create new
        print('Supabase fetch failed: $e');
      }

      // Return cached profile if available, otherwise null
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
      // Update existing profile
      await _supabase
          .from('profiles')
          .update({
            'full_name': profile.fullName,
            'phone': profile.phone,
            'address': profile.address,
            'city': profile.city,
            'pincode': profile.pincode,
            'avatar_url': profile.avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', profile.userId);

      // Update cache
      await _saveProfileToCache(profile.userId, profile);
      
      return profile;
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  /// 🗑️ Clear profile cache (on logout)
  Future<void> clearProfileCache(String userId) async {
    await initialize();
    await _prefs.remove(_getCacheKey(userId));
  }

  /// 📦 Load profile from local cache
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

  /// 📦 Save profile to local cache
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

  /// 🖼️ Decode base64 image string
  static List<int> decodeBase64Image(String base64String) {
    final base64 = base64String.replaceAll('data:image/jpeg;base64,', '');
    return base64Decode(base64);
  }
}
