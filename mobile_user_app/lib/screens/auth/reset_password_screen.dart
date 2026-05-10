// File: reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final String email;
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _success = false;
  String? _apiError;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _passwordController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  PasswordStrength get _strength =>
      PasswordStrength.evaluate(_passwordController.text);

  bool get _canSubmit {
    final p = _passwordController.text;
    final c = _confirmController.text;
    return p.length >= 8 && _strength.level >= 2 && p == c && !_isLoading;
  }

  Future<void> _handleReset() async {
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _apiError = null;
    });
    try {
      final api = ApiService();
      await api.resetPassword(
        widget.email,
        widget.token,
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _apiError = 'Invalid or expired reset link. Please request a new one.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SreaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ResetHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _success
                          ? _SuccessState(
                              key: const ValueKey('success'),
                              onBackToLogin: () => Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (r) => false,
                              ),
                            )
                          : _ResetForm(
                              key: const ValueKey('form'),
                              formKey: _formKey,
                              passwordController: _passwordController,
                              confirmController: _confirmController,
                              passwordFocus: _passwordFocus,
                              confirmFocus: _confirmFocus,
                              strength: _strength,
                              canSubmit: _canSubmit,
                              isLoading: _isLoading,
                              apiError: _apiError,
                              onSubmit: _handleReset,
                            ),
                    ),
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

class _ResetHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ResetHeader({required this.onBack});

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: SreaText.headlineSmall(context).copyWith(
                  color: SreaColors.textOnPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Create a new secure password',
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

class _ResetForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final PasswordStrength strength;
  final bool canSubmit;
  final bool isLoading;
  final String? apiError;
  final VoidCallback onSubmit;

  const _ResetForm({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.strength,
    required this.canSubmit,
    required this.isLoading,
    required this.apiError,
    required this.onSubmit,
  });

  @override
  State<_ResetForm> createState() => _ResetFormState();
}

class _ResetFormState extends State<_ResetForm> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  InputDecoration _inputDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: SreaText.bodySmall(
        context,
      ).copyWith(color: SreaColors.textHint),
      prefixIcon: const Icon(
        Icons.lock_outline_rounded,
        size: 18,
        color: SreaColors.textHint,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: SreaColors.textHint,
        ),
        onPressed: onToggle,
      ),
      contentPadding: SreaSpacing.inputPadding(context),
      filled: true,
      fillColor: SreaColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: SreaRadius.input,
        borderSide: BorderSide(
          color: hasError ? SreaColors.error : SreaColors.border,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SreaRadius.input,
        borderSide: BorderSide(
          color: hasError ? SreaColors.error : SreaColors.borderFocused,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: SreaRadius.input,
        borderSide: const BorderSide(color: SreaColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: SreaRadius.input,
        borderSide: const BorderSide(color: SreaColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordsMatch =
        widget.passwordController.text == widget.confirmController.text &&
        widget.confirmController.text.isNotEmpty;
    final confirmHasError =
        widget.confirmController.text.isNotEmpty && !passwordsMatch;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SreaColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: SreaColors.primary,
              ),
            ),
          ),
          SizedBox(height: SreaSpacing.lg(context)),
          Text(
            'Create new password',
            style: SreaText.headlineSmall(context).copyWith(
              color: SreaColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: SreaSpacing.xs(context)),
          Text(
            'Your new password must be at least 8 characters and include uppercase, lowercase, numbers, and symbols.',
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.textSecondary, height: 1.6),
          ),
          if (widget.apiError != null) ...[
            SizedBox(height: SreaSpacing.md(context)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SreaColors.criticalBg,
                borderRadius: SreaRadius.input,
                border: Border.all(
                  color: SreaColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: SreaColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.apiError!,
                      style: SreaText.bodySmall(
                        context,
                      ).copyWith(color: SreaColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: SreaSpacing.lg(context)),
          SreaInputLabel(label: 'New Password', required: true),
          SizedBox(height: SreaSpacing.inputLabelGap(context)),
          TextFormField(
            controller: widget.passwordController,
            focusNode: widget.passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(widget.confirmFocus),
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.textPrimary),
            decoration: _inputDecoration(
              hint: 'Enter new password',
              obscure: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Minimum 8 characters';
              if (widget.strength.level < 2) return 'Password is too weak';
              return null;
            },
          ),
          if (widget.passwordController.text.isNotEmpty) ...[
            SizedBox(height: SreaSpacing.sm(context)),
            _PasswordStrengthBar(strength: widget.strength),
          ],
          SizedBox(height: SreaSpacing.inputGap(context)),
          SreaInputLabel(label: 'Confirm Password', required: true),
          SizedBox(height: SreaSpacing.inputLabelGap(context)),
          TextFormField(
            controller: widget.confirmController,
            focusNode: widget.confirmFocus,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => widget.onSubmit(),
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.textPrimary),
            decoration: _inputDecoration(
              hint: 'Re-enter password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              hasError: confirmHasError,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != widget.passwordController.text)
                return 'Passwords do not match';
              return null;
            },
          ),
          if (widget.confirmController.text.isNotEmpty) ...[
            SizedBox(height: SreaSpacing.sm(context)),
            Row(
              children: [
                Icon(
                  passwordsMatch
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  size: 14,
                  color: passwordsMatch
                      ? SreaColors.buttonUpdate
                      : SreaColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                  style: SreaText.label(context).copyWith(
                    color: passwordsMatch
                        ? SreaColors.buttonUpdate
                        : SreaColors.error,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: SreaSpacing.xl(context)),
          AnimatedOpacity(
            opacity: widget.canSubmit ? 1.0 : 0.6,
            duration: const Duration(milliseconds: 200),
            child: SreaButton(
              label: 'Reset Password',
              onPressed: widget.canSubmit ? widget.onSubmit : null,
              fullWidth: true,
              isLoading: widget.isLoading,
              size: SreaButtonSize.large,
              icon: Icons.lock_reset_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength.level;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled ? strength.color : SreaColors.border,
                  borderRadius: SreaRadius.pill,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: SreaSpacing.xs(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strength.label,
              style: SreaText.label(
                context,
              ).copyWith(color: strength.color, fontWeight: FontWeight.w600),
            ),
            Text(
              strength.hint,
              style: SreaText.label(
                context,
              ).copyWith(color: SreaColors.textHint),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  final VoidCallback onBackToLogin;
  const _SuccessState({super.key, required this.onBackToLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: SreaSpacing.lg(context)),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF9EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: SreaColors.buttonUpdate,
            ),
          ),
        ),
        SizedBox(height: SreaSpacing.lg(context)),
        Text(
          'Password Updated!',
          style: SreaText.headlineSmall(context).copyWith(
            color: SreaColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: SreaSpacing.sm(context)),
        Text(
          'Your password has been successfully updated. You can now log in with your new password.',
          style: SreaText.bodySmall(
            context,
          ).copyWith(color: SreaColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SreaSpacing.md(context)),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SreaColors.surfaceVariant,
            borderRadius: SreaRadius.input,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: SreaColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'If you did not make this change, contact your barangay admin or MDRRMO immediately.',
                  style: SreaText.label(
                    context,
                  ).copyWith(color: SreaColors.textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: SreaSpacing.xl(context)),
        SreaButton(
          label: 'Back to Login',
          onPressed: onBackToLogin,
          fullWidth: true,
          size: SreaButtonSize.large,
          icon: Icons.login_rounded,
        ),
      ],
    );
  }
}

class PasswordStrength {
  final int level;
  final String label;
  final String hint;
  final Color color;
  const PasswordStrength._({
    required this.level,
    required this.label,
    required this.hint,
    required this.color,
  });

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrength._(
        level: 0,
        label: '',
        hint: '',
        color: SreaColors.border,
      );
    }
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password))
      score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 1) {
      return const PasswordStrength._(
        level: 1,
        label: 'Weak',
        hint: 'Add uppercase, numbers & symbols',
        color: SreaColors.critical,
      );
    } else if (score == 2) {
      return const PasswordStrength._(
        level: 2,
        label: 'Fair',
        hint: 'Add symbols for stronger security',
        color: SreaColors.medium,
      );
    } else if (score == 3) {
      return const PasswordStrength._(
        level: 3,
        label: 'Good',
        hint: 'Almost there!',
        color: SreaColors.high,
      );
    } else {
      return const PasswordStrength._(
        level: 4,
        label: 'Strong',
        hint: 'Great password!',
        color: SreaColors.buttonUpdate,
      );
    }
  }
}
