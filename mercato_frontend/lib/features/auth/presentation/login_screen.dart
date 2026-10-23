import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';

import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  final String selectedRole;

  const LoginScreen({super.key, this.selectedRole = 'USER'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository(DioClient());

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      String targetRoute = AppRoutes.feed;
      if (user.role == 'PLAYER') {
        // Première connexion (profil vide ou incomplet) → compléter le profil.
        final complete = await PlayerProfileRepository(DioClient())
            .isProfileComplete();
        if (!mounted) return;
        targetRoute = complete
            ? AppRoutes.playerDashboard
            : AppRoutes.completeProfile;
      } else if (user.role == 'RECRUITER' || user.role == 'CLUB_AGENT') {
        targetRoute = AppRoutes.scoutingSearch;
      } else if (user.role == 'ADMIN') {
        targetRoute = AppRoutes.adminDashboard;
      }

      Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Identifiants invalides.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ouvre « Mot de passe oublié » avec l'e-mail déjà saisi ; au retour
  /// (mot de passe changé), pré-remplit l'e-mail et vide le mot de passe.
  Future<void> _openForgotPassword() async {
    final email = await Navigator.pushNamed<String>(
      context,
      AppRoutes.forgotPassword,
      arguments: _emailController.text.trim(),
    );
    if (email != null && mounted) {
      _emailController.text = email;
      _passwordController.clear();
    }
  }

  void _showErrorSnackBar(String message) {
    AppSnackbar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // -------- Logo --------
                _AnimatedEntry(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntry(
                  index: 1,
                  child: Text(
                    'Votre carrière commence ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // -------- Carte formulaire --------
                _AnimatedEntry(
                  index: 2,
                  child: Container(
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
                          activeTab: _AuthTab.login,
                          onLoginTap: () {},
                          onRegisterTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                              arguments: widget.selectedRole,
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // -------- Email --------
                        _AuthField(
                          controller: _emailController,
                          label: 'Adresse email',
                          hint: 'ton@email.com',
                          icon: Iconsax.sms,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // -------- Mot de passe --------
                        _AuthField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: '••••••••',
                          icon: Iconsax.lock,
                          obscureText: _isPasswordObscured,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () =>
                                    _isPasswordObscured = !_isPasswordObscured,
                              );
                            },
                            icon: Icon(
                              _isPasswordObscured
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
                              color: colors.iconMuted,
                              size: 20,
                            ),
                          ),
                        ),

                        // -------- Mot de passe oublié --------
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 13,
                                fontWeight: context.weight(FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // -------- Bouton connexion --------
                        _GradientButton(
                          label: 'Se connecter',
                          icon: Iconsax.login,
                          isLoading: _isLoading,
                          onTap: _handleLogin,
                        ),
                      ],
                    ),
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

// ============================================================================
// ONGLETS CONNEXION / INSCRIPTION
// ============================================================================
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

class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedEntry({required this.child, this.index = 0});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
