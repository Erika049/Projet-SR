import 'package:flutter/material.dart';

import '../utils/view_status.dart';
import 'state_views.dart';

/// Affiche chargement / erreur / contenu selon un [DataState].
/// Les données déjà chargées restent visibles en cas d'erreur de rafraîchissement.
class DataStateBuilder<T> extends StatelessWidget {
  const DataStateBuilder({super.key, required this.state, required this.onRetry, required this.builder});

  final DataState<T> state;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    if (data != null) return builder(context, data);
    if (state.status == ViewStatus.failure) return ErrorView(failure: state.failure!, onRetry: onRetry);
    return const LoadingView();
  }
}
