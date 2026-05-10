// File: register_screen.dart
// Path: mobile_user_app/lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srea_shared/srea_shared.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _residencyStatus; // 'resident' or 'non_resident'
  bool get _isResident => _residencyStatus == 'resident';

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_residencyStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your residency status',
            style: SreaText.bodySmall(context).copyWith(color: Colors.white),
          ),
          backgroundColor: SreaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: SreaRadius.input),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final fullName =
          '${_firstNameController.text.trim()} ${_middleNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      await api.register({
        'name': fullName,
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'password_confirmation': _confirmPasswordController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _residencyStatus,
        'barangay':
            null, // FIXED: No default barangay. User will fill it later via Complete Profile.
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Registration failed. Please try again.';
      if (e.toString().contains('email already taken')) {
        errorMsg = 'Email already registered. Please use a different email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: SreaText.bodySmall(context).copyWith(color: Colors.white),
          ),
          backgroundColor: SreaColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SreaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _CompactHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Personal Information'),
                      SizedBox(height: SreaSpacing.sectionHeaderGap(context)),

                      SreaTextField(
                        label: 'First Name',
                        hint: 'Enter first name',
                        controller: _firstNameController,
                        required: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: SreaSpacing.inputGap(context)),

                      SreaTextField(
                        label: 'Middle Name',
                        hint: 'Enter middle name (optional)',
                        controller: _middleNameController,
                      ),
                      SizedBox(height: SreaSpacing.inputGap(context)),

                      SreaTextField(
                        label: 'Last Name',
                        hint: 'Enter last name',
                        controller: _lastNameController,
                        required: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: SreaSpacing.inputGap(context)),

                      SreaTextField(
                        label: 'Email',
                        hint: 'example@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        required: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      SizedBox(height: SreaSpacing.inputGap(context)),

                      SreaTextField(
                        label: 'Contact Number',
                        hint: '09XXXXXXXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        required: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 11)
                            return 'Enter a valid 11-digit number';
                          return null;
                        },
                      ),
                      SizedBox(height: SreaSpacing.inputGap(context)),

                      _SectionHeader(title: 'Residency Status'),
                      SizedBox(height: SreaSpacing.sectionHeaderGap(context)),
                      SreaRadioGroup<String>(
                        groupValue: _residencyStatus,
                        onChanged: (v) => setState(() => _residencyStatus = v),
                        options: const [
                          SreaRadioItem(
                            label: 'Resident of San Rafael',
                            value: 'resident',
                            subtitle: 'I live in San Rafael, Bulacan',
                          ),
                          SreaRadioItem(
                            label: 'Non-Resident',
                            value: 'non_resident',
                            subtitle: 'I do not reside in San Rafael',
                          ),
                        ],
                      ),

                      if (_isResident)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SreaColors.primaryLight,
                            borderRadius: SreaRadius.input,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: SreaColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You can complete your address and ID later in your profile.',
                                  style: SreaText.label(
                                    context,
                                  ).copyWith(color: SreaColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: SreaSpacing.sectionGap(context)),
                      _SectionHeader(title: 'Password'),
                      SizedBox(height: SreaSpacing.sectionHeaderGap(context)),

                      SreaPasswordField(
                        label: 'Password',
                        hint: 'Enter password',
                        controller: _passwordController,
                        required: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 8) return 'Minimum 8 characters';
                          return null;
                        },
                      ),
                      SizedBox(height: SreaSpacing.inputGap(context)),

                      SreaPasswordField(
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        controller: _confirmPasswordController,
                        required: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),

                      const SizedBox(height: 36),
                      SreaButton(
                        label: 'Register',
                        onPressed: _handleRegister,
                        fullWidth: true,
                        isLoading: _isLoading,
                        size: SreaButtonSize.large,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account?  ',
                              style: SreaText.bodySmall(
                                context,
                              ).copyWith(color: SreaColors.textSecondary),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: SreaText.bodySmall(context).copyWith(
                                    color: SreaColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _CompactHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SreaColors.primaryDark, SreaColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: SreaColors.textOnPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: SreaText.headlineSmall(
                  context,
                ).copyWith(color: SreaColors.textOnPrimary, fontSize: 20),
              ),
              Text(
                'Fill in the details below to register',
                style: SreaText.label(
                  context,
                ).copyWith(color: SreaColors.bottomNavInactive),
              ),
            ],
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
