import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import '../models/profile.dart';
import 'auth/login_screen.dart';
import 'profile_edit_screen.dart';
import 'services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileService _profileService;
  Profile? _profile;
  bool _loading = true;
  final User? _authUser = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_authUser == null) return;

    setState(() => _loading = true);
    try {
      final profile = await _profileService.loadProfile(_authUser.id);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Clear cached profile
    if (_authUser != null) {
      await _profileService.clearProfileCache(_authUser.id);
    }

    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _goToEditProfile() async {
    if (_profile == null) return;

    final updatedProfile = await Navigator.push<Profile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(profile: _profile!),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Magiil Mart Support',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('📧 Email: magiilmartppm@gmail.com'),
              Text('📱 Phone: 9842062624 , 9445883008'),
              
              SizedBox(height: 12),
              Text(
                'FAQ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• How do I track my order?'),
              Text('  Orders are tracked in the Orders tab'),
              SizedBox(height: 8),
              Text('• How do I cancel an order?'),
              Text('  Contact support for cancellations'),
              SizedBox(height: 8),
              Text('• Is my data secure?'),
              Text('  Yes, we use industry-standard encryption'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A2E4A)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 👤 PROFILE HEADER CARD
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Avatar
                              _buildAvatar(),
                              const SizedBox(height: 16),

                              // Full Name or email
                              Text(
                                _profile?.fullName ?? _authUser?.email?.split('@')[0] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Email (read-only)
                              Text(
                                _authUser?.email ?? 'Not available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📋 PROFILE INFO CARD
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_profile?.phone != null)
                              _buildInfoTile(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: _profile!.phone!,
                              ),
                            if (_profile?.phone != null) const Divider(height: 1),
                            if (_profile?.address != null)
                              _buildInfoTile(
                                icon: Icons.location_on,
                                label: 'Address',
                                value: _profile!.address!,
                              ),
                            if (_profile?.address != null) const Divider(height: 1),
                            if (_profile?.city != null)
                              _buildInfoTile(
                                icon: Icons.apartment,
                                label: 'City',
                                value: _profile!.city!,
                              ),
                            if (_profile?.city != null) const Divider(height: 1),
                            if (_profile?.pincode != null)
                              _buildInfoTile(
                                icon: Icons.mail,
                                label: 'Pincode',
                                value: _profile!.pincode!,
                              ),
                            _buildInfoTile(
                              icon: Icons.calendar_today,
                              label: 'Member Since',
                              value: _formatDate(_profile?.createdAt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🔧 ACCOUNT ACTIONS CARD
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildActionTile(
                              icon: Icons.edit,
                              title: 'Edit Profile',
                              trailing: Icons.arrow_forward_ios,
                              onTap: _goToEditProfile,
                            ),
                            const Divider(height: 1),
                            _buildActionTile(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              trailing: Icons.arrow_forward_ios,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notification settings coming soon!'),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            _buildActionTile(
                              icon: Icons.help,
                              title: 'Help & Support',
                              trailing: Icons.arrow_forward_ios,
                              onTap: _showHelpDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🚪 LOGOUT BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// 🎨 Build avatar with optional image
  Widget _buildAvatar() {
    try {
      if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty) {
        // Try to decode base64 image
        if (_profile!.avatarUrl!.startsWith('data:image')) {
          final base64Data = _profile!.avatarUrl!.replaceAll('data:image/jpeg;base64,', '');
          return CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(base64Decode(base64Data)),
          );
        }
      }
    } catch (e) {
      print('Error loading avatar: $e');
    }

    // Default avatar
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B3E5E), Color(0xFF8B5A7E)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  /// 📋 Build info tile
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFC9A347).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5A2E4A), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C2C2C),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// 🔧 Build action tile
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    IconData? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5A2E4A), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2C2C),
        ),
      ),
      trailing: trailing != null
          ? Icon(trailing, size: 14, color: Colors.grey.shade400)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// 📅 Format date
  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return '${date.day}/${date.month}/${date.year}';
  }
}
