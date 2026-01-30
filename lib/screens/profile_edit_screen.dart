import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../models/profile.dart';
import 'services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final Profile profile;

  const ProfileEditScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  String? _selectedImageBase64;
  bool _saving = false;
  late ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();

    _fullNameController = TextEditingController(text: widget.profile.fullName ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _addressController = TextEditingController(text: widget.profile.address ?? '');
    _cityController = TextEditingController(text: widget.profile.city ?? '');
    _pincodeController = TextEditingController(text: widget.profile.pincode ?? '');

    // Load existing avatar
    if (widget.profile.avatarUrl != null) {
      _selectedImageBase64 = widget.profile.avatarUrl;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  /// 🖼️ Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _selectedImageBase64 = ProfileService.encodeImageToBase64(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// ✅ Validate form
  bool _validateForm() {
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final pincode = _pincodeController.text.trim();

    if (name.isEmpty) {
      _showError('Full name cannot be empty');
      return false;
    }

    if (phone.isNotEmpty) {
      if (phone.length < 10 || phone.length > 15 || !_isNumeric(phone)) {
        _showError('Phone number must be between 10-15 digits');
        return false;
      }
    }

    if (pincode.isNotEmpty && !_isNumeric(pincode)) {
      _showError('Pincode must contain only numbers');
      return false;
    }

    return true;
  }

  /// 🔢 Check if string is numeric
  bool _isNumeric(String s) {
    return s.replaceAll('-', '').replaceAll('+', '').replaceAll(' ', '').codeUnits.every((codeUnit) {
      return codeUnit >= 48 && codeUnit <= 57;
    });
  }

  /// 💾 Save profile
  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() => _saving = true);

    try {
      final updatedProfile = widget.profile.copyWith(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        avatarUrl: _selectedImageBase64,
      );

      await _profileService.saveProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return updated profile to previous screen
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error saving profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// ❌ Show error dialog
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  /// 🖼️ Display avatar
  Widget _buildAvatarDisplay() {
    if (_selectedImageBase64 != null && _selectedImageBase64!.isNotEmpty) {
      try {
        if (_selectedImageBase64!.startsWith('data:image')) {
          final base64Data = _selectedImageBase64!.replaceAll('data:image/jpeg;base64,', '');
          return Image.memory(base64Decode(base64Data), fit: BoxFit.cover);
        }
      } catch (e) {
        print('Error displaying avatar: $e');
      }
    }

    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ PROFILE PICTURE SECTION
              const SizedBox(height: 8),
              Text(
                'Profile Picture',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A2E4A),
                    ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      _buildAvatarDisplay(),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A2E4A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to change picture (gallery only)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // 📝 FORM FIELDS
              _buildTextField(
                label: 'Full Name',
                controller: _fullNameController,
                icon: Icons.person,
                hint: 'Enter your full name',
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone,
                hint: 'Enter your phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Address',
                controller: _addressController,
                icon: Icons.location_on,
                hint: 'Enter your address',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'City',
                controller: _cityController,
                icon: Icons.apartment,
                hint: 'Enter your city',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Pincode',
                controller: _pincodeController,
                icon: Icons.mail,
                hint: 'Enter your pincode',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // 💾 SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF5A2E4A),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ❌ CANCEL BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Build text field with icon
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A2E4A),
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF5A2E4A), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF5A2E4A),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
