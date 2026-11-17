import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Gabarit commun des écrans : bandeau blanc (flèche de retour + titre de la page)
/// puis contenu défilant sur fond gris-bleu.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, this.children, this.body, this.onRefresh, this.bottom})
    : assert(children != null || body != null);

  final String title;

  /// Contenu affiché dans une liste défilante avec les marges standard.
  final List<Widget>? children;

  /// Contenu libre (remplace [children]).
  final Widget? body;

  /// Active le « tirer pour rafraîchir ».
  final Future<void> Function()? onRefresh;

  /// Zone fixe en bas de l'écran (ex. bouton « Enregistrer »).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    Widget content =
        body ??
        ListView(padding: AppTheme.pagePadding, physics: const AlwaysScrollableScrollPhysics(), children: children!);
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: SafeArea(
              bottom: false,
              // Barre du haut : flèche de retour (si possible) suivie du titre de la page.
              child: Padding(
                padding: EdgeInsets.fromLTRB(canPop ? 4 : 20, canPop ? 4 : 12, 20, canPop ? 4 : 12),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        tooltip: 'Retour',
                        icon: Icon(Icons.arrow_back_rounded, color: AppColors.navy),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: content),
          if (bottom != null)
            SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: bottom),
            ),
        ],
      ),
    );
  }
}
