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

/// Mot de passe oublié — étape 3 sur 3 : choix du nouveau mot de passe.
class NewPasswordPage extends StatelessWidget {
  const NewPasswordPage({super.key, required this.resetToken});

  /// Jeton renvoyé par le serveur après validation du code SMS.
  final String resetToken;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<NewPasswordCubit>(), child: _NewPasswordView(resetToken: resetToken));
}

class _NewPasswordView extends StatefulWidget {
  const _NewPasswordView({required this.resetToken});
  final String resetToken;

  @override
  State<_NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<_NewPasswordView> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<NewPasswordCubit>().submit((
      resetToken: widget.resetToken,
      password: _password.text,
      confirmation: _confirmation.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NewPasswordCubit>().state;
    return BlocListener<NewPasswordCubit, SubmitState>(
      listener: (context, s) {
        if (s.status == ViewStatus.failure) context.showMessage(s.error!, error: true);
        if (s.isDone) {
          context.showMessage('Mot de passe modifié. Connectez-vous avec votre nouveau mot de passe.');
          context.go(Routes.login);
        }
      },
      child: AuthLayout(
        title: 'Nouveau mot de passe',
        subtitle: 'Choisissez un mot de passe d’au moins 8 caractères. Il remplacera l’ancien.',
        step: (current: 3, total: 3),
        footer: AuthLink(text: 'Vous changez d’avis ?', action: 'Annuler', onTap: () => context.go(Routes.login)),
        children: [
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _password,
                    hint: 'Nouveau mot de passe',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscure: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.newPassword,
                  ),
                  gap12,
                  AppTextField(
                    controller: _confirmation,
                    hint: 'Confirmer le mot de passe',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => v != _password.text ? 'Les deux mots de passe ne correspondent pas' : null,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
          gap20,
          AppButton(label: 'Enregistrer', loading: state.isSubmitting, onPressed: _submit),
        ],
      ),
    );
  }
}
