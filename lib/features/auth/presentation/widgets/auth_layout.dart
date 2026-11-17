import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

/// Gabarit commun des écrans d'authentification : bandeau marine arrondi
/// (flèche de retour, titre de la page, sous-titre) puis formulaire défilant.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.children, this.subtitle, this.step, this.footer});

  final String title;
  final String? subtitle;

  /// Étape courante d'un parcours en deux temps (inscription → vérification).
  final ({int current, int total})? step;

  final List<Widget> children;

  /// Lien affiché en bas de l'écran (« Vous n'avez pas de compte ? … »).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(title: title, subtitle: subtitle, step: step, canPop: canPop),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                  ),
                ],
              ),
            ),
          ),
          if (footer != null)
            SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(24, 4, 24, 12), child: footer),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.canPop, this.subtitle, this.step});

  final String title;
  final String? subtitle;
  final ({int current, int total})? step;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(canPop ? 4 : 24, canPop ? 4 : 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre du haut : flèche de retour suivie du titre de la page.
              Row(
                children: [
                  if (canPop)
                    IconButton(
                      tooltip: 'Retour',
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (subtitle != null || step != null)
                Padding(
                  // Aligné sur le titre, après la flèche (48 px).
                  padding: EdgeInsets.only(left: canPop ? 48 : 0, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 15, height: 1.35),
                        ),
                      if (step != null) ...[
                        const SizedBox(height: 12),
                        _StepIndicator(current: step!.current, total: step!.total),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == current ? 36 : 18,
            height: 6,
            decoration: BoxDecoration(
              color: i <= current ? AuthLogo.accent : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 12),
        Text(
          'Étape $current sur $total',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Logo SchoolConnect (assets/images/logo.png) posé sur un carré blanc arrondi,
/// pour rester lisible sur le fond marine, en thème clair comme en sombre.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.size = 112});

  static const asset = 'assets/images/logo.png';

  /// Vert d'accent de la page d'accueil.
  static const accent = Color(0xFF4FD1A5);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.27)),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Logo SchoolConnect',
      ),
    );
  }
}

/// Texte suivi d'un lien : « Vous n'avez pas de compte ? S'inscrire ».
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, AppTheme.minTouchTarget),
          ),
          child: Text(action, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
