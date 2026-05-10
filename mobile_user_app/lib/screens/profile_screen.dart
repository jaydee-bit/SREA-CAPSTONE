// File: profile_screen.dart
// Path: mobile_user_app/lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srea_shared/srea_shared.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'auth/login_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String?)? onProfileImageUpdated;
  final VoidCallback? onRefreshNeeded;
  const ProfileScreen({
    super.key,
    this.onProfileImageUpdated,
    this.onRefreshNeeded,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _user = {};
  bool _isLoading = true;
  String? _error;

  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;

  String? _selectedGender;
  String? _profileImageUrl;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingProfileImage = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  bool get _hasCompletedProfile {
    if (_user['role'] != 'resident') return false;
    return (_user['street']?.isNotEmpty == true) &&
        (_user['province']?.isNotEmpty == true) &&
        (_user['municipality']?.isNotEmpty == true) &&
        (_user['valid_id_photo']?.isNotEmpty == true);
  }

  String get _verificationStatus {
    if (_user['role'] != 'resident') return '';
    if (!_hasCompletedProfile) return 'Unverified';
    if (!(_user['is_verified'] ?? false)) return 'Pending Verification';
    return 'Verified';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final user = await api.getUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _profileImageUrl = user['profile_image'];
        _initializeControllers();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    final nameParts = (_user['name'] ?? '').trim().split(' ');
    String firstName = '';
    String middleName = '';
    String lastName = '';
    if (nameParts.isNotEmpty) {
      firstName = nameParts.first;
      lastName = nameParts.last;
      if (nameParts.length > 2) {
        middleName = nameParts.sublist(1, nameParts.length - 1).join(' ');
      }
    }
    _firstNameController = TextEditingController(text: firstName);
    _middleNameController = TextEditingController(text: middleName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: _user['email'] ?? '');
    _phoneController = TextEditingController(text: _user['phone'] ?? '');
    _birthDateController = TextEditingController(
      text: _user['birth_date'] ?? '',
    );
    // Normalize gender from API to match dropdown options exactly.
    // Guards against casing mismatches (e.g. "male" vs "Male" from backend).
    final rawGender = _user['gender']?.toString();
    _selectedGender = rawGender != null
        ? _genderOptions.firstWhere(
            (o) => o.toLowerCase() == rawGender.toLowerCase(),
            orElse: () => rawGender,
          )
        : null;
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: SreaRadius.bottomSheet),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: SreaColors.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _uploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: SreaColors.primary),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _uploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(ImageSource source) async {
    setState(() => _isUploadingProfileImage = true);
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        final api = ApiService();
        final compressed = await api.compressImage(File(picked.path));
        final imageUrl = await api.uploadProfileImage(compressed);
        if (!mounted) return;
        setState(() {
          _profileImageUrl = imageUrl;
        });
        widget.onProfileImageUpdated?.call(imageUrl);
        final updatedUser = await api.getUser();
        if (!mounted) return;
        setState(() {
          _user = updatedUser;
          _profileImageUrl = updatedUser['profile_image'];
          _initializeControllers();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: SreaColors.buttonUpdate,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture'),
            backgroundColor: SreaColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formValid()) return;
    setState(() => _isSaving = true);
    try {
      final api = ApiService();

      final String firstName = _firstNameController.text.trim();
      final String middleName = _middleNameController.text.trim();
      final String lastName = _lastNameController.text.trim();

      String fullName = firstName;
      if (middleName.isNotEmpty) fullName += ' $middleName';
      fullName += ' $lastName';

      final Map<String, dynamic> updateData = {
        'name': fullName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _birthDateController.text.trim(),
      };
      await api.updateProfile(updateData);
      final updatedUser = await api.getUser();
      if (!mounted) return;
      setState(() {
        _user = updatedUser;
        _profileImageUrl = updatedUser['profile_image'];
        _initializeControllers();
        _isEditing = false;
        _isSaving = false;
      });
      widget.onProfileImageUpdated?.call(_profileImageUrl);
      widget.onRefreshNeeded?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: SreaColors.buttonUpdate,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: SreaColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _formValid() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  Future<void> _logout() async {
    try {
      final api = ApiService();
      await api.logout();
    } catch (_) {}
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty
          ? DateTime.parse(_birthDateController.text)
          : DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SreaColors.primary,
              onPrimary: SreaColors.textOnPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T').first;
      });
      if (_isEditing) await _saveChanges();
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void _changePassword() async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() {
                isLoading = true;
                errorMessage = null;
              });
              try {
                final api = ApiService();
                await api.changePassword(
                  currentPasswordController.text.trim(),
                  newPasswordController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: SreaColors.buttonUpdate,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                setDialogState(() {
                  isLoading = false;
                  errorMessage = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: SreaRadius.modal),
              title: Text(
                'Change Password',
                style: SreaText.titleLarge(
                  context,
                ).copyWith(color: SreaColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SreaPasswordField(
                        label: 'Current Password',
                        hint: 'Enter current password',
                        controller: currentPasswordController,
                        required: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      SreaPasswordField(
                        label: 'New Password',
                        hint: 'Enter new password (min. 8 characters)',
                        controller: newPasswordController,
                        required: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'Minimum 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SreaPasswordField(
                        label: 'Confirm New Password',
                        hint: 'Re-enter new password',
                        controller: confirmPasswordController,
                        required: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != newPasswordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: SreaColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: SreaText.bodySmall(
                      context,
                    ).copyWith(color: SreaColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : _changePassword,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Update',
                          style: SreaText.bodySmall(
                            context,
                          ).copyWith(color: SreaColors.primary),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateForDisplay(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Not set';
    try {
      final DateTime date = DateTime.parse(isoDate);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return 'Not set';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SreaColors.background,
        appBar: AppBar(
          backgroundColor: SreaColors.primary,
          elevation: 0,
          title: Text(
            'My Profile',
            style: SreaText.titleLarge(
              context,
            ).copyWith(color: SreaColors.textOnPrimary),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: SreaColors.background,
        appBar: AppBar(
          backgroundColor: SreaColors.primary,
          elevation: 0,
          title: Text(
            'My Profile',
            style: SreaText.titleLarge(
              context,
            ).copyWith(color: SreaColors.textOnPrimary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: SreaText.bodySmall(
                  context,
                ).copyWith(color: SreaColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isResident = _user['role'] == 'resident';
    final fullName = '${_firstNameController.text} ${_lastNameController.text}'
        .trim();
    final displayBirthDate = _formatDateForDisplay(_birthDateController.text);
    final idPhotoUrl =
        _user['valid_id_photo'] != null && _user['valid_id_photo'].isNotEmpty
        ? ApiService().getFullImageUrl(_user['valid_id_photo'])
        : null;

    return Scaffold(
      backgroundColor: SreaColors.background,
      appBar: AppBar(
        backgroundColor: SreaColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: SreaColors.textOnPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  // Re-normalize in case _user was updated since last load
                  final rawGender = _user['gender']?.toString();
                  _selectedGender = rawGender != null
                      ? _genderOptions.firstWhere(
                          (o) => o.toLowerCase() == rawGender.toLowerCase(),
                          orElse: () => rawGender,
                        )
                      : null;
                });
              },
              child: Text(
                'Edit',
                style: SreaText.label(
                  context,
                ).copyWith(color: SreaColors.textOnPrimary),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save',
                      style: SreaText.label(
                        context,
                      ).copyWith(color: SreaColors.textOnPrimary),
                    ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _ProfileHeader(
                userName: fullName,
                email: _emailController.text,
                verificationStatus: _verificationStatus,
                imageUrl: _profileImageUrl,
                isUploading: _isUploadingProfileImage,
                onImageTap: _pickProfileImage,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Personal Information'),
                    const SizedBox(height: 12),
                    SreaCard(
                      child: Column(
                        children: [
                          _ProfileField(
                            label: 'First Name',
                            value: _firstNameController.text,
                            isEditing: _isEditing,
                            onEdit: (v) => _firstNameController.text = v,
                            child: SreaTextField(
                              hint: 'First Name',
                              controller: _firstNameController,
                              required: true,
                            ),
                          ),
                          const Divider(height: 1, color: SreaColors.divider),
                          _ProfileField(
                            label: 'Middle Name',
                            value: _middleNameController.text,
                            isEditing: _isEditing,
                            onEdit: (v) => _middleNameController.text = v,
                            child: SreaTextField(
                              hint: 'Middle Name',
                              controller: _middleNameController,
                            ),
                          ),
                          const Divider(height: 1, color: SreaColors.divider),
                          _ProfileField(
                            label: 'Last Name',
                            value: _lastNameController.text,
                            isEditing: _isEditing,
                            onEdit: (v) => _lastNameController.text = v,
                            child: SreaTextField(
                              hint: 'Last Name',
                              controller: _lastNameController,
                              required: true,
                            ),
                          ),
                          const Divider(height: 1, color: SreaColors.divider),
                          _ProfileField(
                            label: 'Gender',
                            value: _selectedGender ?? '',
                            isEditing: _isEditing,
                            onEdit: (v) => setState(() => _selectedGender = v),
                            child: SreaDropdown<String>(
                              hint: 'Select Gender',
                              value: _selectedGender,
                              items: _genderOptions,
                              onChanged: (v) =>
                                  setState(() => _selectedGender = v),
                            ),
                          ),
                          const Divider(height: 1, color: SreaColors.divider),
                          _ReadOnlyField(
                            label: 'Birth Date',
                            value: displayBirthDate,
                            onTap: _isEditing ? _selectBirthDate : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Contact Information'),
                    const SizedBox(height: 12),
                    SreaCard(
                      child: Column(
                        children: [
                          _ProfileField(
                            label: 'Email',
                            value: _emailController.text,
                            isEditing: _isEditing,
                            onEdit: (v) => _emailController.text = v,
                            child: SreaTextField(
                              hint: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              required: true,
                            ),
                          ),
                          const Divider(height: 1, color: SreaColors.divider),
                          _ProfileField(
                            label: 'Phone',
                            value: _phoneController.text,
                            isEditing: _isEditing,
                            onEdit: (v) => _phoneController.text = v,
                            child: SreaTextField(
                              hint: '09XXXXXXXXX',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              required: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isResident) ...[
                      const SizedBox(height: 20),
                      _SectionHeader(title: 'Address & Verification'),
                      const SizedBox(height: 12),
                      SreaCard(
                        child: Column(
                          children: [
                            _ReadOnlyField(
                              label: 'Province',
                              value: _user['province']?.isNotEmpty == true
                                  ? _user['province']
                                  : 'Not set',
                            ),
                            const Divider(height: 1, color: SreaColors.divider),
                            _ReadOnlyField(
                              label: 'Municipality',
                              value: _user['municipality']?.isNotEmpty == true
                                  ? _user['municipality']
                                  : 'Not set',
                            ),
                            const Divider(height: 1, color: SreaColors.divider),
                            _ReadOnlyField(
                              label: 'Barangay',
                              value: _user['barangay']?.isNotEmpty == true
                                  ? _user['barangay']
                                  : 'Not set',
                            ),
                            const Divider(height: 1, color: SreaColors.divider),
                            _ReadOnlyField(
                              label: 'Street',
                              value: _user['street']?.isNotEmpty == true
                                  ? _user['street']
                                  : 'Not set',
                            ),
                            const Divider(height: 1, color: SreaColors.divider),
                            _ReadOnlyField(
                              label: 'Valid ID Type',
                              value: _user['valid_id_type']?.isNotEmpty == true
                                  ? _user['valid_id_type']
                                  : 'Not set',
                            ),
                            const Divider(height: 1, color: SreaColors.divider),
                            _ReadOnlyIdPhotoField(
                              label: 'ID Photo',
                              photoUrl: idPhotoUrl,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (!_isEditing)
                      SreaButton.outline(
                        label: 'Change Password',
                        onPressed: _showChangePasswordDialog,
                        fullWidth: true,
                        icon: Icons.lock_outline_rounded,
                      ),
                    const SizedBox(height: 12),
                    if (!_isEditing)
                      SreaButton.report(
                        label: 'Logout',
                        onPressed: _logout,
                        fullWidth: true,
                        icon: Icons.logout_rounded,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== Helper widgets (unchanged from your original) ==========
class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String email;
  final String verificationStatus;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onImageTap;
  const _ProfileHeader({
    required this.userName,
    required this.email,
    required this.verificationStatus,
    this.imageUrl,
    required this.isUploading,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SreaColors.primaryDark, SreaColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onImageTap,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: SreaColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_outline_rounded,
                              size: 44,
                              color: SreaColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline_rounded,
                            size: 44,
                            color: SreaColors.primary,
                          ),
                  ),
                ),
                if (isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SreaColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: SreaText.titleLarge(context).copyWith(
              color: SreaColors.textOnPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.bottomNavInactive),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildStatusBadge(context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;
    switch (verificationStatus) {
      case 'Verified':
        bgColor = Colors.white;
        textColor = SreaColors.primary;
        icon = Icons.verified_rounded;
        label = 'Verified Account';
        break;
      case 'Pending Verification':
        bgColor = Colors.white.withOpacity(0.15);
        textColor = SreaColors.textOnPrimary;
        icon = Icons.pending_outlined;
        label = 'Pending Verification';
        break;
      case 'Unverified':
        bgColor = Colors.white.withOpacity(0.15);
        textColor = SreaColors.textOnPrimary;
        icon = Icons.error_outline_rounded;
        label = 'Unverified';
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SreaRadius.pill,
        border: verificationStatus != 'Verified'
            ? Border.all(color: Colors.white.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: SreaText.label(
              context,
            ).copyWith(color: textColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: SreaColors.primary,
            borderRadius: SreaRadius.pill,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: SreaText.titleLarge(
            context,
          ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditing;
  final Function(String) onEdit;
  final Widget child;
  const _ProfileField({
    required this.label,
    required this.value,
    required this.isEditing,
    required this.onEdit,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: SreaText.label(
                context,
              ).copyWith(color: SreaColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isEditing
                ? child
                : Text(
                    value.isEmpty ? 'Not set' : value,
                    style: SreaText.bodySmall(
                      context,
                    ).copyWith(color: SreaColors.textPrimary),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ReadOnlyField({required this.label, required this.value, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: SreaText.label(
                  context,
                ).copyWith(color: SreaColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: SreaText.bodySmall(
                  context,
                ).copyWith(color: SreaColors.textPrimary),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit, size: 16, color: SreaColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyIdPhotoField extends StatelessWidget {
  final String label;
  final String? photoUrl;
  const _ReadOnlyIdPhotoField({required this.label, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: SreaText.label(
                context,
              ).copyWith(color: SreaColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          insetPadding: EdgeInsets.zero,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: InteractiveViewer(
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Image.network(
                                photoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(SreaRadius.sm),
                      child: Image.network(
                        photoUrl!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: SreaColors.textHint,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    'Not uploaded',
                    style: TextStyle(color: SreaColors.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }
}
