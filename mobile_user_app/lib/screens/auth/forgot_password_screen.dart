// File: forgot_password_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _submitted = false;
  String? _emailError;
  int _cooldown = 0;
  Timer? _cooldownTimer;

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
    _emailController.addListener(_validateEmailRealTime);
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _validateEmailRealTime() {
    final v = _emailController.text;
    if (v.isEmpty) {
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
    final newError = isValid ? null : 'Enter a valid email address';
    if (newError != _emailError) setState(() => _emailError = newError);
  }

  bool get _canSubmit =>
      _emailController.text.isNotEmpty &&
      _emailError == null &&
      !_isLoading &&
      _cooldown == 0;

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send reset link. Please try again later.',
            style: SreaText.bodySmall(context).copyWith(color: Colors.white),
          ),
          backgroundColor: SreaColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startCooldown({int seconds = 60}) {
    setState(() => _cooldown = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
      } else {
        if (mounted) setState(() => _cooldown--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_cooldown > 0) return;
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reset link resent successfully.',
            style: SreaText.bodySmall(context).copyWith(color: Colors.white),
          ),
          backgroundColor: SreaColors.buttonUpdate,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to resend reset link. Please try again later.',
            style: SreaText.bodySmall(context).copyWith(color: Colors.white),
          ),
          backgroundColor: SreaColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SreaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ForgotHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _submitted
                          ? _SuccessState(
                              key: const ValueKey('success'),
                              email: _emailController.text,
                              cooldown: _cooldown,
                              isLoading: _isLoading,
                              onResend: _handleResend,
                              onBackToLogin: () => Navigator.pop(context),
                            )
                          : _FormState(
                              key: const ValueKey('form'),
                              formKey: _formKey,
                              emailController: _emailController,
                              emailFocus: _emailFocus,
                              emailError: _emailError,
                              isLoading: _isLoading,
                              canSubmit: _canSubmit,
                              onSubmit: _handleSubmit,
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

class _ForgotHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ForgotHeader({required this.onBack});

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
                'Forgot Password',
                style: SreaText.headlineSmall(context).copyWith(
                  color: SreaColors.textOnPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'We\'ll help you get back in',
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

class _FormState extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final String? emailError;
  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onSubmit;

  const _FormState({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.emailFocus,
    required this.emailError,
    required this.isLoading,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
                Icons.lock_reset_rounded,
                size: 40,
                color: SreaColors.primary,
              ),
            ),
          ),
          SizedBox(height: SreaSpacing.lg(context)),
          Text(
            'Reset your password',
            style: SreaText.headlineSmall(context).copyWith(
              color: SreaColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: SreaSpacing.sm(context)),
          Text(
            'Enter the email address associated with your SREA account and we\'ll send you a password reset link.',
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.textSecondary, height: 1.6),
          ),
          SizedBox(height: SreaSpacing.xl(context)),
          SreaInputLabel(label: 'Email Address', required: true),
          SizedBox(height: SreaSpacing.inputLabelGap(context)),
          TextFormField(
            controller: emailController,
            focusNode: emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'example@gmail.com',
              hintStyle: SreaText.bodySmall(
                context,
              ).copyWith(color: SreaColors.textHint),
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                size: 18,
                color: SreaColors.textHint,
              ),
              suffixIcon: emailController.text.isNotEmpty
                  ? Icon(
                      emailError == null
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: emailError == null
                          ? SreaColors.buttonUpdate
                          : SreaColors.error,
                    )
                  : null,
              errorText: emailError,
              errorStyle: SreaText.label(
                context,
              ).copyWith(color: SreaColors.error),
              contentPadding: SreaSpacing.inputPadding(context),
              filled: true,
              fillColor: SreaColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: SreaRadius.input,
                borderSide: BorderSide(
                  color: emailError != null
                      ? SreaColors.error
                      : SreaColors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: SreaRadius.input,
                borderSide: BorderSide(
                  color: emailError != null
                      ? SreaColors.error
                      : SreaColors.borderFocused,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: SreaRadius.input,
                borderSide: const BorderSide(color: SreaColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: SreaRadius.input,
                borderSide: const BorderSide(
                  color: SreaColors.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: SreaSpacing.xl(context)),
          AnimatedOpacity(
            opacity: canSubmit ? 1.0 : 0.6,
            duration: const Duration(milliseconds: 200),
            child: SreaButton(
              label: 'Send Reset Link',
              onPressed: canSubmit ? onSubmit : null,
              fullWidth: true,
              isLoading: isLoading,
              size: SreaButtonSize.large,
              icon: Icons.send_rounded,
            ),
          ),
          SizedBox(height: SreaSpacing.lg(context)),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  text: 'Remember your password?  ',
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
    );
  }
}

class _SuccessState extends StatelessWidget {
  final String email;
  final int cooldown;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  const _SuccessState({
    super.key,
    required this.email,
    required this.cooldown,
    required this.isLoading,
    required this.onResend,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: SreaSpacing.md(context)),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF9EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 46,
            color: SreaColors.buttonUpdate,
          ),
        ),
        SizedBox(height: SreaSpacing.lg(context)),
        Text(
          'Check your email',
          style: SreaText.headlineSmall(context).copyWith(
            color: SreaColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: SreaSpacing.sm(context)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SreaColors.primaryLight,
            borderRadius: SreaRadius.card,
            border: Border.all(
              color: SreaColors.borderFocused.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'If an account with ${email.isNotEmpty ? email : 'that email'} exists, a password reset link has been sent. Please check your inbox and spam folder.',
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.primary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: SreaSpacing.sm(context)),
        Text(
          'The link will expire in 30 minutes.',
          style: SreaText.label(context).copyWith(color: SreaColors.textHint),
        ),
        SizedBox(height: SreaSpacing.xl(context)),
        SreaButton(
          label: 'Back to Login',
          onPressed: onBackToLogin,
          fullWidth: true,
          size: SreaButtonSize.large,
          icon: Icons.arrow_back_rounded,
        ),
        SizedBox(height: SreaSpacing.md(context)),
        AnimatedOpacity(
          opacity: cooldown > 0 ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: SreaButton(
            label: cooldown > 0 ? 'Resend in ${cooldown}s' : 'Resend Email',
            onPressed: cooldown > 0 ? null : onResend,
            fullWidth: true,
            isLoading: isLoading,
            size: SreaButtonSize.medium,
            type: SreaButtonType.outline,
            icon: cooldown > 0 ? Icons.timer_outlined : Icons.refresh_rounded,
          ),
        ),
        SizedBox(height: SreaSpacing.lg(context)),
        _EmailTips(),
      ],
    );
  }
}

class _EmailTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SreaColors.surfaceVariant,
        borderRadius: SreaRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Didn\'t receive it?',
            style: SreaText.bodySmall(context).copyWith(
              fontWeight: FontWeight.w700,
              color: SreaColors.textPrimary,
            ),
          ),
          SizedBox(height: SreaSpacing.sm(context)),
          _TipRow(text: 'Check your spam or junk folder'),
          _TipRow(text: 'Make sure the email address is correct'),
          _TipRow(text: 'Wait a few minutes before retrying'),
          _TipRow(text: 'Contact MDRRMO if the issue persists'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;
  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 5, color: SreaColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: SreaText.label(
                context,
              ).copyWith(color: SreaColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
