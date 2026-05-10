// File: complete_profile_screen.dart
// Path: mobile_user_app/lib/screens/complete_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingId = false;

  String? _barangay;
  final _streetController = TextEditingController();
  String? _validIdType;
  File? _idImage;
  String? _uploadedIdPath;

  final _provinceController = TextEditingController(text: 'Bulacan');
  final _municipalityController = TextEditingController(text: 'San Rafael');

  final List<String> _barangayOptions = [
    'Banca-Banca',
    'BMA – Balagtas',
    'Caingin',
    'Capihan',
    'Coral na Bato',
    'Cruz na Daan',
    'Dagat-Dagatan',
    'Diliman I',
    'Diliman II',
    'Libis',
    'Lico',
    'Maasim',
    'Mabalas-Balas',
    'Maguinao',
    'Maronquillo',
    'Paco',
    'Pansumaloc',
    'Pantubig',
    'Pasong Bangkal',
    'Pasong Callos',
    'Pasong Intsik',
    'Pinacpinacan',
    'Poblacion',
    'Pulo',
    'Pulong Bayabas',
    'Salapungan',
    'Sampaloc',
    'San Agustin',
    'San Roque',
    'Sapang Pahalang',
    'Talacsan',
    'Tambubong',
    'Tukod',
    'Ulingao',
  ];

  final List<String> _validIdOptions = [
    'PhilSys / National ID',
    'Driver\'s License',
    'Passport',
    'Voter\'s ID',
    'Postal ID',
    'SSS ID',
    'GSIS ID',
    'Barangay ID',
  ];

  @override
  void dispose() {
    _streetController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    super.dispose();
  }

  Future<void> _pickIdImage() async {
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
                await _uploadIdPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: SreaColors.primary),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _uploadIdPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadIdPhoto(ImageSource source) async {
    setState(() => _isUploadingId = true);
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        final api = ApiService();
        final compressed = await api.compressImage(File(picked.path));
        final relativePath = await api.uploadImage(compressed);
        setState(() {
          _idImage = File(picked.path);
          _uploadedIdPath = relativePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID photo uploaded'),
            backgroundColor: SreaColors.buttonUpdate,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload ID photo'),
          backgroundColor: SreaColors.error,
        ),
      );
    } finally {
      setState(() => _isUploadingId = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_barangay == null) {
      _showError('Please select your barangay');
      return;
    }
    if (_validIdType == null) {
      _showError('Please select your valid ID type');
      return;
    }
    if (_uploadedIdPath == null) {
      _showError('Please upload a photo of your valid ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      await api.updateProfile({
        'province': 'Bulacan',
        'municipality': 'San Rafael',
        'barangay': _barangay,
        'street': _streetController.text.trim(),
        'valid_id_type': _validIdType,
        'valid_id_photo': _uploadedIdPath,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile completed! Your account is now pending verification.',
          ),
          backgroundColor: SreaColors.buttonUpdate,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: SreaColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Complete Your Profile',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Address'),
                const SizedBox(height: 12),

                SreaTextField(
                  label: 'Province',
                  hint: 'Bulacan',
                  controller: _provinceController,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                SreaTextField(
                  label: 'Municipality',
                  hint: 'San Rafael',
                  controller: _municipalityController,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                SreaDropdown<String>(
                  label: 'Barangay',
                  hint: 'Choose your Barangay',
                  value: _barangay,
                  items: _barangayOptions,
                  required: true,
                  onChanged: (v) => setState(() => _barangay = v),
                  validator: (v) =>
                      v == null ? 'Please select your barangay' : null,
                ),
                const SizedBox(height: 16),

                SreaTextField(
                  label: 'Street / House No.',
                  hint: 'Enter your address',
                  controller: _streetController,
                  required: true,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'Valid ID'),
                const SizedBox(height: 12),

                SreaDropdown<String>(
                  label: 'Valid ID',
                  hint: 'Choose your ID type',
                  value: _validIdType,
                  items: _validIdOptions,
                  required: true,
                  onChanged: (v) => setState(() => _validIdType = v),
                  validator: (v) =>
                      v == null ? 'Please select an ID type' : null,
                ),
                const SizedBox(height: 16),

                SreaImageUpload(
                  label: 'Upload ID Photo',
                  hint: 'Tap to upload your ID',
                  selectedImage: _idImage,
                  onTap: _pickIdImage,
                  onRemove: () => setState(() {
                    _idImage = null;
                    _uploadedIdPath = null;
                  }),
                ),
                if (_isUploadingId)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (_uploadedIdPath != null && !_isUploadingId)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'ID uploaded successfully',
                      style: SreaText.label(
                        context,
                      ).copyWith(color: SreaColors.low),
                    ),
                  ),

                const SizedBox(height: 32),
                SreaButton(
                  label: 'Submit for Verification',
                  onPressed: _submit,
                  fullWidth: true,
                  isLoading: _isLoading,
                  size: SreaButtonSize.large,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
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
