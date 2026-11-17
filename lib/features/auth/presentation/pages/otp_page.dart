import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../state/auth_form_cubits.dart';
import '../state/session_cubit.dart';
import '../widgets/auth_layout.dart';
import '../widgets/otp_code_field.dart';

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
  String _code = '';

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final user = await context.read<OtpCubit>().verify(_code);
    if (user != null && mounted) await context.read<SessionCubit>().signedIn(user);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OtpCubit>().state;

    return BlocListener<OtpCubit, OtpState>(
      listenWhen: (a, b) => b.submit.status == ViewStatus.failure && a.submit != b.submit,
      listener: (context, s) => context.showMessage(s.submit.error!, error: true),
      child: AuthLayout(
        title: 'Vérification',
        subtitle: 'Saisissez le code à 6 chiffres reçu par SMS au ${widget.phone}.',
        step: (current: 2, total: 2),
        children: [
          OtpCodeField(
            onChanged: (c) => setState(() => _code = c),
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Vérifier',
            loading: state.submit.isSubmitting,
            onPressed: _code.length == AppConstants.otpLength ? _verify : null,
          ),
          gap12,
          ResendCodeLink(secondsLeft: state.secondsLeft, onResend: () => context.read<OtpCubit>().resend()),
        ],
      ),
    );
  }
}
