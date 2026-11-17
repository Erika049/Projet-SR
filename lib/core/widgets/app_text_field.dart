import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Champ de saisie standard (fond gris-bleu, bord arrondi).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.enabled = true,
    this.prefixIcon,
    this.autofillHints,
  });

  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextAlign textAlign;
  final bool enabled;

  /// Icône affichée à gauche du champ (écrans d’authentification).
  final IconData? prefixIcon;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _hidden,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      textAlign: widget.textAlign,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      style: const TextStyle(fontSize: 17, color: AppColors.navy),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 22),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? 'Afficher' : 'Masquer',
                icon: Icon(
                  _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
