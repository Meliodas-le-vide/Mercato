import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';

import '../data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedRole;

  const RegisterScreen({super.key, this.selectedRole = 'USER'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _lastnameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository(DioClient());

  late String _activeRole;
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _activeRole = widget.selectedRole;
  }

  @override
  void dispose() {
    _lastnameController.dispose();
    _firstnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_lastnameController.text.isEmpty ||
        _firstnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackBar(
        message: 'Veuillez remplir tous les champs obligatoires.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.register(
        lastname: _lastnameController.text.trim(),
        firstname: _firstnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _activeRole,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      _showSnackBar(message: 'Compte créé ! Connecte-toi.', isError: false);

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
        arguments: _activeRole,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(message: 'Erreur lors de l\'inscription.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar({required String message, required bool isError}) {
    if (isError) {
      AppSnackbar.error(context, message);
    } else {
      AppSnackbar.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // -------- Logo + tagline --------
              Image.asset('assets/images/logo.png', width: 100, height: 100),
              const SizedBox(height: 12),
              Text(
                'Votre carrière commence ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 28),

              // -------- Carte formulaire --------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // -------- Onglets --------
                    _AuthTabs(
                      activeTab: _AuthTab.register,
                      onLoginTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                          arguments: _activeRole,
                        );
                      },
                      onRegisterTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // -------- Nom --------
                    _AuthField(
                      controller: _lastnameController,
                      label: 'Nom',
                      hint: 'Dupont',
                      icon: Iconsax.user,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // -------- Prénom --------
                    _AuthField(
                      controller: _firstnameController,
                      label: 'Prénom',
                      hint: 'Jean',
                      icon: Iconsax.user,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // -------- Email --------
                    _AuthField(
                      controller: _emailController,
                      label: 'Adresse email',
                      hint: 'ton@email.com',
                      icon: Iconsax.sms,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // -------- Téléphone --------
                    _AuthField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      hint: '+33 6 12 34 56 78',
                      icon: Iconsax.call,
                      helper: 'Optionnel',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    // -------- Mot de passe --------
                    _AuthField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      hint: '••••••••',
                      icon: Iconsax.lock,
                      obscureText: _isPasswordObscured,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleRegister(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _isPasswordObscured = !_isPasswordObscured,
                          );
                        },
                        icon: Icon(
                          _isPasswordObscured ? Iconsax.eye_slash : Iconsax.eye,
                          color: colors.iconMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // -------- Bouton inscription --------
                    _GradientButton(
                      label: 'S\'inscrire',
                      icon: Iconsax.tick_circle,
                      isLoading: _isLoading,
                      onTap: _handleRegister,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // -------- Conditions --------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'En continuant, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AuthTab { login, register }

class _AuthTabs extends StatelessWidget {
  final _AuthTab activeTab;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const _AuthTabs({
    required this.activeTab,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLogin = activeTab == _AuthTab.login;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onLoginTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(
                  'Connexion',
                  style: TextStyle(
                    color: isLogin ? colors.textPrimary : colors.textSecondary,
                    fontWeight: isLogin
                        ? context.weight(FontWeight.w700)
                        : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  color: isLogin ? AppColors.accentOrange : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onRegisterTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(
                  'Inscription',
                  style: TextStyle(
                    color: !isLogin ? colors.textPrimary : colors.textSecondary,
                    fontWeight: !isLogin
                        ? context.weight(FontWeight.w700)
                        : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  color: !isLogin ? AppColors.accentOrange : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helper;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.helper,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFocused = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: context.weight(FontWeight.w600),
                  letterSpacing: 0.3,
                ),
              ),
              if (widget.helper != null) ...[
                const Spacer(),
                Text(
                  widget.helper!,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? AppColors.accentOrange.withValues(alpha: 0.5)
                  : colors.border,
              width: isFocused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            onSubmitted: widget.onSubmitted,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: colors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                widget.icon,
                size: 20,
                color: isFocused ? AppColors.accentOrange : colors.iconMuted,
              ),
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: AppLoader(size: 20),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: context.weight(FontWeight.w700),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
