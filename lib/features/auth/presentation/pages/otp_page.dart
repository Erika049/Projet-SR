import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../state/auth_form_cubits.dart';
import '../state/session_cubit.dart';
import '../widgets/auth_layout.dart';

/// « Vérification » — étape 2 sur 2 : code SMS à 6 chiffres.
class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => OtpCubit(sl<VerifyOtp>(), sl<ResendOtp>(), phone),
    child: _OtpView(phone: phone),
  );
}

class _OtpView extends StatefulWidget {
  const _OtpView({required this.phone});
  final String phone;

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
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
    if (_code.length == AppConstants.otpLength) _verify();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final user = await context.read<OtpCubit>().verify(_code);
    if (user != null && mounted) await context.read<SessionCubit>().signedIn(user);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OtpCubit>().state;
    final seconds = state.secondsLeft.toString().padLeft(2, '0');

    return BlocListener<OtpCubit, OtpState>(
      listenWhen: (a, b) => b.submit.status == ViewStatus.failure && a.submit != b.submit,
      listener: (context, s) => context.showMessage(s.submit.error!, error: true),
      child: AuthLayout(
        title: 'Vérification',
        subtitle: 'Saisissez le code à 6 chiffres reçu par SMS au ${widget.phone}.',
        step: (current: 2, total: 2),
        children: [
          Row(
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
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Vérifier',
            loading: state.submit.isSubmitting,
            onPressed: _code.length == AppConstants.otpLength ? _verify : null,
          ),
          gap12,
          Center(
            child: state.canResend
                ? TextButton(
                    onPressed: () => context.read<OtpCubit>().resend(),
                    child: const Text('Renvoyer le code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  )
                : HelpText('Renvoyer le code dans 00:$seconds', center: true),
          ),
        ],
      ),
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
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
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
