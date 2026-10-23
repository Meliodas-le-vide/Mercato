import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/core/widgets/app_text_field.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';

import '../data/auth_repository.dart';

enum _ResetStep { email, code, password }

/// Mot de passe oublié en 3 étapes :
/// 1. e-mail → envoi d'un code à 6 chiffres
/// 2. saisie du code
/// 3. nouveau mot de passe → retour à la connexion
class ForgotPasswordScreen extends StatefulWidget {
  /// E-mail déjà saisi sur l'écran de connexion (pré-rempli).
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _minPasswordLength = 6;

  final _authRepository = AuthRepository(DioClient());
  final _formKey = GlobalKey<FormState>();

  late final _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String get _email => _emailController.text.trim().toLowerCase();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Message renvoyé par le backend, ou message par défaut.
  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'];
    }
    return fallback;
  }

  Future<void> _run(Future<void> Function() action, String fallback) async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, _errorMessage(e, fallback));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- Étape 1 : envoi du code ----
  Future<void> _sendCode() => _run(() async {
    await _authRepository.forgotPassword(_email);
    if (!mounted) return;
    AppSnackbar.success(
      context,
      'Si un compte existe pour $_email, un code vient d\'être envoyé.',
      title: 'Code envoyé',
    );
    _codeController.clear();
    setState(() => _step = _ResetStep.code);
  }, 'Impossible d\'envoyer le code pour le moment.');

  // ---- Étape 2 : vérification du code ----
  Future<void> _verifyCode() => _run(() async {
    await _authRepository.verifyResetCode(
      email: _email,
      code: _codeController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _step = _ResetStep.password);
  }, 'Code invalide.');

  // ---- Étape 3 : nouveau mot de passe ----
  Future<void> _resetPassword() => _run(() async {
    await _authRepository.resetPassword(
      email: _email,
      code: _codeController.text.trim(),
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    AppSnackbar.success(
      context,
      'Ton mot de passe a été modifié. Tu peux te connecter.',
      title: 'C\'est fait !',
    );
    Navigator.pop(context, _email);
  }, 'Impossible de modifier le mot de passe.');

  void _goBack() {
    switch (_step) {
      case _ResetStep.email:
        Navigator.pop(context);
      case _ResetStep.code:
        setState(() => _step = _ResetStep.email);
      case _ResetStep.password:
        setState(() => _step = _ResetStep.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopScope(
      canPop: _step == _ResetStep.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: colors.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.icon, size: 18),
            onPressed: _isLoading ? null : _goBack,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                _StepIndicator(current: _step.index),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      _ResetStep.email => _buildEmailStep(colors),
                      _ResetStep.code => _buildCodeStep(colors),
                      _ResetStep.password => _buildPasswordStep(colors),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppSemanticColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.accentOrange, size: 28),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 24,
            fontWeight: context.weight(FontWeight.w800),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildEmailStep(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.lock_reset_rounded,
          title: 'Mot de passe oublié ?',
          subtitle:
              'Saisis l\'e-mail de ton compte : nous t\'enverrons un code à '
              '6 chiffres pour choisir un nouveau mot de passe.',
          colors: colors,
        ),
        AppTextField(
          controller: _emailController,
          label: 'E-mail',
          hint: 'exemple@mail.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return 'L\'e-mail est obligatoire';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
              return 'E-mail invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 28),
        GoldButton(
          width: double.infinity,
          fontSize: 15,
          label: 'Envoyer le code',
          icon: Icons.send_rounded,
          loading: _isLoading,
          onPressed: _isLoading ? null : _sendCode,
        ),
      ],
    );
  }

  Widget _buildCodeStep(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.mark_email_read_outlined,
          title: 'Vérifie tes e-mails',
          subtitle:
              'Saisis le code à 6 chiffres envoyé à $_email. '
              'Il est valable 15 minutes.',
          colors: colors,
        ),
        AppTextField(
          controller: _codeController,
          label: 'Code de vérification',
          hint: '••••••',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          textStyle: TextStyle(
            fontSize: 22,
            letterSpacing: 10,
            fontWeight: context.weight(FontWeight.w700),
          ),
          validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
              ? null
              : 'Le code contient 6 chiffres',
        ),
        const SizedBox(height: 28),
        GoldButton(
          width: double.infinity,
          fontSize: 15,
          label: 'Vérifier le code',
          icon: Icons.check_rounded,
          loading: _isLoading,
          onPressed: _isLoading ? null : _verifyCode,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _sendCode,
          child: Text(
            'Je n\'ai rien reçu — renvoyer un code',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontSize: 13.5,
              fontWeight: context.weight(FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(AppSemanticColors colors) {
    final toggle = IconButton(
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        size: 20,
        color: colors.iconMuted,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.password_rounded,
          title: 'Nouveau mot de passe',
          subtitle:
              'Choisis un mot de passe d\'au moins $_minPasswordLength '
              'caractères. Tu seras déconnecté de tes autres appareils.',
          colors: colors,
        ),
        AppTextField(
          controller: _passwordController,
          label: 'Nouveau mot de passe',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffix: toggle,
          validator: (v) => (v ?? '').length < _minPasswordLength
              ? 'Au moins $_minPasswordLength caractères'
              : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _confirmController,
          label: 'Confirmer le mot de passe',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          validator: (v) => v != _passwordController.text
              ? 'Les mots de passe ne correspondent pas'
              : null,
        ),
        const SizedBox(height: 28),
        GoldButton(
          width: double.infinity,
          fontSize: 15,
          label: 'Changer le mot de passe',
          icon: Icons.check_circle_outline_rounded,
          loading: _isLoading,
          onPressed: _isLoading ? null : _resetPassword,
        ),
      ],
    );
  }
}

/// Trois barres indiquant l'étape en cours.
class _StepIndicator extends StatelessWidget {
  final int current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                color: i <= current
                    ? AppColors.accentOrange
                    : colors.textTertiary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
