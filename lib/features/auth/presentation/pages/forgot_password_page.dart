import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../state/auth_form_cubits.dart';
import '../widgets/auth_layout.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<ForgotPasswordCubit>(), child: const _ForgotView());
}

class _ForgotView extends StatefulWidget {
  const _ForgotView();

  @override
  State<_ForgotView> createState() => _ForgotViewState();
}

class _ForgotViewState extends State<_ForgotView> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordCubit>().submit(_phone.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ForgotPasswordCubit>().state;
    return BlocListener<ForgotPasswordCubit, SubmitState>(
      listener: (context, s) {
        if (s.status == ViewStatus.failure) context.showMessage(s.error!, error: true);
        if (s.isDone) context.push(Routes.resetCode, extra: _phone.text.trim());
      },
      child: AuthLayout(
        title: 'Mot de passe oublié',
        subtitle: 'Entrez votre numéro de téléphone. Nous vous envoyons un code pour choisir un nouveau mot de passe.',
        step: (current: 1, total: 3),
        footer: AuthLink(
          text: 'Vous vous en souvenez ?',
          action: 'Retour à la connexion',
          onTap: () => context.canPop() ? context.pop() : context.go(Routes.login),
        ),
        children: [
          Form(
            key: _form,
            child: AppTextField(
              controller: _phone,
              hint: '+237 6XX XXX XXX',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: Validators.phone,
              onSubmitted: (_) => _submit(),
            ),
          ),
          gap20,
          AppButton(label: 'Envoyer le code', loading: state.isSubmitting, onPressed: _submit),
        ],
      ),
    );
  }
}
