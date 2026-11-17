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
import '../state/session_cubit.dart';
import '../widgets/auth_layout.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(create: (_) => sl<LoginCubit>(), child: const _LoginView());
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final user = await context.read<LoginCubit>().submit(_phone.text, _password.text);
    if (user != null && mounted) await context.read<SessionCubit>().signedIn(user);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LoginCubit>().state;

    return BlocListener<LoginCubit, SubmitState>(
      listenWhen: (a, b) => b.status == ViewStatus.failure,
      listener: (context, s) => context.showMessage(s.error!, error: true),
      child: AuthLayout(
        title: 'Connexion',
        subtitle: 'Heureux de vous revoir ! Connectez-vous avec votre numéro de téléphone.',
        footer: AuthLink(
          text: 'Vous n’avez pas de compte ?',
          action: 'S’inscrire',
          onTap: () => context.push(Routes.register),
        ),
        children: [
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _phone,
                    hint: '+237 6XX XXX XXX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: Validators.phone,
                  ),
                  gap12,
                  AppTextField(
                    controller: _password,
                    hint: 'Mot de passe',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4)),
              onPressed: () => context.push(Routes.forgotPassword),
              child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          gap12,
          AppButton(label: 'Se connecter', loading: state.isSubmitting, onPressed: _submit),
        ],
      ),
    );
  }
}
