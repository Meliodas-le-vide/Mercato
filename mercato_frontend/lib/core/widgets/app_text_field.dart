import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

/// Champ de formulaire simple : un libellé au-dessus d'un champ standard
/// qui reprend le style `inputDecorationTheme` de l'AppTheme.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool required;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? textStyle;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.required = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _LabeledField(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        obscureText: obscureText,
        maxLength: maxLength,
        textAlign: textAlign,
        style: TextStyle(
          color: readOnly ? colors.textTertiary : colors.textPrimary,
          fontSize: 15,
        ).merge(textStyle),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: _prefixIcon(context, icon),
          suffixIcon: suffix,
          counterText: '',
        ),
      ),
    );
  }
}

/// Liste déroulante au même style que [AppTextField].
/// [options] : valeur envoyée → libellé affiché.
class AppDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;
  final String hint;
  final IconData? icon;
  final bool required;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = 'Sélectionner',
    this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _LabeledField(
      label: label,
      required: required,
      child: DropdownButtonFormField<String>(
        initialValue: options.containsKey(value) ? value : null,
        isExpanded: true,
        dropdownColor: colors.surface,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconMuted),
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        hint: Text(hint),
        decoration: InputDecoration(prefixIcon: _prefixIcon(context, icon)),
        items: [
          for (final entry in options.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Champ « sélecteur » (date, heure…) au même style que [AppTextField] :
/// affiche [value] (ou [hint] si null) et appelle [onTap] au toucher.
class AppPickerField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final String hint;
  final IconData? icon;
  final IconData trailingIcon;
  final bool required;

  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.hint,
    this.icon,
    this.trailingIcon = Icons.keyboard_arrow_down_rounded,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _LabeledField(
      label: label,
      required: required,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: _prefixIcon(context, icon),
            suffixIcon: Icon(
              trailingIcon,
              size: 18,
              color: AppColors.accentOrange,
            ),
          ),
          child: Text(
            value ?? '',
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de date (jj/mm/aaaa) au même style que [AppTextField].
class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String hint;
  final IconData? icon;
  final bool required;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Sélectionner une date',
    this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final date = value;

    return AppPickerField(
      label: label,
      required: required,
      hint: hint,
      icon: icon,
      trailingIcon: Icons.calendar_today_outlined,
      onTap: onTap,
      value: date == null
          ? null
          : '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year}',
    );
  }
}

Widget? _prefixIcon(BuildContext context, IconData? icon) {
  if (icon == null) return null;
  return Icon(icon, size: 20, color: context.colors.iconMuted);
}

/// Libellé (avec * si obligatoire) au-dessus d'un champ.
class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: context.weight(FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
