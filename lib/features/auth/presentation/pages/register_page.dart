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

/// « Créer un compte » — étape 1 sur 2.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(create: (_) => sl<RegisterCubit>(), child: const _RegisterView());
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await context.read<RegisterCubit>().submit((
      fullName: _name.text,
      phone: _phone.text,
      email: _email.text,
      password: _password.text,
    ));
    if (ok && mounted) context.push(Routes.otp, extra: _phone.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegisterCubit>().state;
    return BlocListener<RegisterCubit, SubmitState>(
      listenWhen: (a, b) => b.status == ViewStatus.failure,
      listener: (context, s) => context.showMessage(s.error!, error: true),
      child: AuthLayout(
        title: 'Créer un compte',
        subtitle: 'Renseignez vos informations pour suivre la scolarité de vos enfants.',
        step: (current: 1, total: 2),
        footer: AuthLink(
          text: 'Vous avez déjà un compte ?',
          action: 'Se connecter',
          onTap: () => context.canPop() ? context.pop() : context.go(Routes.login),
        ),
        children: [
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  hint: 'Nom complet',
                  prefixIcon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => Validators.required(v, 'Le nom'),
                ),
                gap12,
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
                  controller: _email,
                  hint: 'Email (facultatif)',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => Validators.email(v, optional: true),
                ),
                gap12,
                AppTextField(
                  controller: _password,
                  hint: 'Mot de passe (6 caractères min.)',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          gap20,
          AppButton(label: 'Envoyer', loading: state.isSubmitting, onPressed: _submit),
          const HelpText('Un code de vérification vous sera envoyé par SMS.', center: true),
        ],
      ),
    );
  }
}
