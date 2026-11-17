import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../state/auth_form_cubits.dart';
import '../widgets/auth_layout.dart';
import '../widgets/otp_code_field.dart';

/// Mot de passe oublié — étape 2 sur 3 : code reçu par SMS.
class ResetCodePage extends StatelessWidget {
  const ResetCodePage({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ResetCodeCubit(sl<VerifyResetCode>(), sl<RequestPasswordReset>(), phone),
    child: _ResetCodeView(phone: phone),
  );
}

class _ResetCodeView extends StatefulWidget {
  const _ResetCodeView({required this.phone});
  final String phone;

  @override
  State<_ResetCodeView> createState() => _ResetCodeViewState();
}

class _ResetCodeViewState extends State<_ResetCodeView> {
  String _code = '';

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final token = await context.read<ResetCodeCubit>().verify(_code);
    // Le code n'est plus utile : on remplace l'écran pour que « retour » ne le réaffiche pas.
    if (token != null && mounted) context.pushReplacement(Routes.newPassword, extra: token);
  }

  Future<void> _resend() async {
    await context.read<ResetCodeCubit>().resend();
    if (mounted) context.showMessage('Nouveau code envoyé.');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ResetCodeCubit>().state;

    return BlocListener<ResetCodeCubit, OtpState>(
      listenWhen: (a, b) => b.submit.status == ViewStatus.failure && a.submit != b.submit,
      listener: (context, s) => context.showMessage(s.submit.error!, error: true),
      child: AuthLayout(
        title: 'Code de vérification',
        subtitle:
            'Si un compte est associé au ${widget.phone}, un code à 6 chiffres vient de lui être envoyé par SMS.',
        step: (current: 2, total: 3),
        footer: AuthLink(
          text: 'Mauvais numéro ?',
          action: 'Modifier',
          onTap: () => context.canPop() ? context.pop() : context.go(Routes.forgotPassword),
        ),
        children: [
          OtpCodeField(
            onChanged: (c) => setState(() => _code = c),
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Valider le code',
            loading: state.submit.isSubmitting,
            onPressed: _code.length == AppConstants.otpLength ? _verify : null,
          ),
          gap12,
          ResendCodeLink(secondsLeft: state.secondsLeft, onResend: _resend),
        ],
      ),
    );
  }
}
