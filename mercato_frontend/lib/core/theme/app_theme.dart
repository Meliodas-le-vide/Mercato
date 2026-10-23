import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  /// Police globale de l'application (Google Fonts).
  /// Note : `GoogleFonts.questrialTextTheme` est incompatible avec google_fonts 9
  /// (il renvoie le TextTheme de material_ui) → on passe par `fontFamily`.
  static String? get fontFamily => GoogleFonts.questrial().fontFamily;

  /// Allège une graisse pour le mode clair.
  /// Questrial n'a qu'une graisse : le moteur simule le gras dès w600,
  /// donc seuls les titres très appuyés (w800/w900) restent en gras.
  static FontWeight lighten(FontWeight weight) {
    if (weight == FontWeight.w900) return FontWeight.w700;
    if (weight == FontWeight.w800) return FontWeight.w600;
    if (weight == FontWeight.w700 || weight == FontWeight.w600) {
      return FontWeight.w500;
    }
    return weight;
  }

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        surfaceVariant: AppColors.surfaceVariantDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        textTertiary: AppColors.textTertiaryDark,
        icon: AppColors.textPrimaryDark,
        iconMuted: AppColors.textSecondaryDark,
        border: AppColors.borderDark,
        divider: AppColors.dividerDark,
        shadow: Colors.black.withValues(alpha: 0.4),
        appBarBackground: AppColors.surfaceDark,
        navBarBackground: AppColors.surfaceDark,
        navUnselected: AppColors.navUnselectedDark,
      );

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        surfaceVariant: AppColors.surfaceVariantLight,
        textPrimary: AppColors.textPrimaryLight,
        textSecondary: AppColors.textSecondaryLight,
        textTertiary: AppColors.textTertiaryLight,
        icon: AppColors.textPrimaryLight,
        iconMuted: AppColors.textSecondaryLight,
        border: AppColors.borderLight,
        divider: AppColors.dividerLight,
        shadow: Colors.black.withValues(alpha: 0.06),
        appBarBackground: AppColors.surfaceLight,
        navBarBackground: AppColors.surfaceLight,
        navUnselected: AppColors.navUnselectedLight,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color icon,
    required Color iconMuted,
    required Color border,
    required Color divider,
    required Color shadow,
    required Color appBarBackground,
    required Color navBarBackground,
    required Color navUnselected,
  }) {
    final isDark = brightness == Brightness.dark;
    FontWeight w(FontWeight weight) => isDark ? weight : lighten(weight);

    // ---- Base theme ----
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Applique Questrial à tout le textTheme et aux composants.
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      primaryColor: AppColors.accentOrange,
      cardColor: surface,
      dividerColor: divider,
      disabledColor: textTertiary,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accentOrange,
        onPrimary: AppColors.onGold,
        secondary: AppColors.primaryYellow,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        error: AppColors.error,
        onError: Colors.white,
        outline: border,
      ),
    );

    // ---- Text theme avec Questrial ----
    final text = base.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(

      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -1.2,
        ),
        displayMedium: text.displayMedium?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -1.0,
        ),
        displaySmall: text.displaySmall?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -0.8,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -0.6,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -0.4,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -0.2,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: w(FontWeight.w700),
          letterSpacing: -0.2,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontWeight: w(FontWeight.w600),
        ),
        titleSmall: text.titleSmall?.copyWith(
          fontWeight: w(FontWeight.w600),
        ),
        bodyLarge: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: text.bodySmall?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: w(FontWeight.w600),
          letterSpacing: 0.1,
        ),
        labelMedium: text.labelMedium?.copyWith(
          fontWeight: w(FontWeight.w600),
        ),
        labelSmall: text.labelSmall?.copyWith(
          color: textTertiary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),

 
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: icon),
        actionsIconTheme: IconThemeData(color: icon),
        titleTextStyle: GoogleFonts.questrial(
          color: isDark ? AppColors.primaryYellow : textPrimary,
          fontSize: 18,
          fontWeight: w(FontWeight.w700),
          letterSpacing: -0.2,
        ),
      ),

      iconTheme: IconThemeData(color: icon),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

   
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 2,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),

   
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        hintStyle: GoogleFonts.questrial(
          color: textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.questrial(
          color: textSecondary,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.accentOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: AppColors.onGold,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.questrial(
            fontSize: 16,
            fontWeight: w(FontWeight.w700),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.questrial(
            fontSize: 15,
            fontWeight: w(FontWeight.w700),
            letterSpacing: 0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: GoogleFonts.questrial(
            fontSize: 13,
            fontWeight: w(FontWeight.w600),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.questrial(
            fontSize: 14,
            fontWeight: w(FontWeight.w600),
          ),
        ),
      ),


      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBarBackground,
        selectedItemColor: AppColors.accentOrange,
        unselectedItemColor: navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.questrial(
          fontWeight: w(FontWeight.w700),
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.questrial(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground,
        indicatorColor: AppColors.accentOrange.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.questrial(
            fontSize: 12,
            fontWeight: selected ? w(FontWeight.w700) : FontWeight.w400,
            color: selected ? AppColors.accentOrange : navUnselected,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accentOrange : navUnselected,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: isDark ? surface : const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.questrial(
          color: Colors.white,
          fontSize: 14,
        ),
      ),

      extensions: <ThemeExtension<dynamic>>[
        AppSemanticColors(
          background: background,
          surface: surface,
          surfaceVariant: surfaceVariant,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textTertiary: textTertiary,
          icon: icon,
          iconMuted: iconMuted,
          border: border,
          divider: divider,
          shadow: shadow,
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          verified: AppColors.verifiedBadge,
        ),
      ],
    );
  }
}


class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color icon;
  final Color iconMuted;

  final Color border;
  final Color divider;
  final Color shadow;

  final Color success;
  final Color warning;
  final Color error;
  final Color verified;

  const AppSemanticColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.icon,
    required this.iconMuted,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.error,
    required this.verified,
  });

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? icon,
    Color? iconMuted,
    Color? border,
    Color? divider,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? error,
    Color? verified,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      icon: icon ?? this.icon,
      iconMuted: iconMuted ?? this.iconMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      verified: verified ?? this.verified,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      verified: Color.lerp(verified, other.verified, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
  AppSemanticColors get colors => semantic;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isLight => !isDark;

  /// Graisse adaptée au mode : identique en sombre, allégée en clair.
  FontWeight weight(FontWeight weight) =>
      isDark ? weight : AppTheme.lighten(weight);
}