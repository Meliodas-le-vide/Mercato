import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(
    BuildContext context,
    String message, {
    String title = 'Succès',
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.success,
      duration: duration,
      backgroundColor: AppColors.success,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String title = 'Erreur',
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.failure,
      duration: duration,
      backgroundColor: context.colors.error,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String title = 'Attention',
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.warning,
      duration: duration,
      backgroundColor: AppColors.accentOrange,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String title = 'Info',
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      title: title,
      message: message,
      contentType: ContentType.help,
      duration: duration,
      backgroundColor: context.colors.textPrimary,
    );
  }

  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
    required Duration duration,
    required Color backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        padding: EdgeInsets.zero,
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: contentType,
          color: backgroundColor,
          titleTextStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 16,
            fontWeight: context.weight(FontWeight.w700),
          ),
          messageTextStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
