import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Gabarit commun des écrans : bandeau blanc (« SCHOOLCONNECT » + titre)
/// puis contenu défilant sur fond gris-bleu.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    this.eyebrow = 'SCHOOLCONNECT',
    this.children,
    this.body,
    this.onRefresh,
    this.bottom,
  }) : assert(children != null || body != null);

  final String title;
  final String eyebrow;

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
              child: Padding(
                padding: EdgeInsets.fromLTRB(canPop ? 4 : 20, 12, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (canPop)
                      IconButton(
                        tooltip: 'Retour',
                        icon: Icon(Icons.arrow_back_rounded, color: AppColors.navy),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(title, style: Theme.of(context).textTheme.headlineMedium),
                        ],
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
