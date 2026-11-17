import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/widgets.dart';

/// Saisie d'un code SMS en 6 cases (inscription et mot de passe oublié).
///
/// Passe automatiquement à la case suivante, accepte le collage d'un code
/// complet et appelle [onCompleted] dès que le 6e chiffre est saisi.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({super.key, required this.onChanged, required this.onCompleted});

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _controllers = List.generate(AppConstants.otpLength, (_) => TextEditingController());
  final _nodes = List.generate(AppConstants.otpLength, (_) => FocusNode());

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String value) {
    if (value.length > 1) {
      // Collage d'un code complet.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < _controllers.length; j++) {
        _controllers[j].text = j < digits.length ? digits[j] : '';
      }
      _nodes.last.requestFocus();
    } else if (value.isNotEmpty && i < _nodes.length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
    final code = _code;
    widget.onChanged(code);
    if (code.length == AppConstants.otpLength) {
      FocusScope.of(context).unfocus();
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _controllers.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _OtpBox(
              controller: _controllers[i],
              node: _nodes[i],
              autofocus: i == 0,
              onChanged: (v) => _onChanged(i, v),
            ),
          ),
        ],
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.controller, required this.node, required this.onChanged, this.autofocus = false});

  final TextEditingController controller;
  final FocusNode node;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.isNotEmpty;
    return AspectRatio(
      aspectRatio: 0.85,
      child: TextField(
        controller: controller,
        focusNode: node,
        autofocus: autofocus,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        expands: true,
        maxLines: null,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          fillColor: filled ? AppColors.surface : AppColors.background,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            borderSide: BorderSide(color: filled ? AppColors.navy : AppColors.border, width: filled ? 1.6 : 1.2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Lien « Renvoyer le code » ou compte à rebours, sous la saisie du code.
class ResendCodeLink extends StatelessWidget {
  const ResendCodeLink({super.key, required this.secondsLeft, required this.onResend});

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (secondsLeft > 0) {
      return HelpText('Renvoyer le code dans 00:${secondsLeft.toString().padLeft(2, '0')}', center: true);
    }
    return Center(
      child: TextButton(
        onPressed: onResend,
        child: const Text('Renvoyer le code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
