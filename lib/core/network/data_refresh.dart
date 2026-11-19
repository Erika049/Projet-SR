import 'dart:async';

import 'package:flutter/foundation.dart';

/// Signal « les données du serveur ont peut-être changé ».
///
/// Émis après chaque requête d'écriture réussie (envoi d'un appel, d'un justificatif, d'une note…),
/// au retour de l'application au premier plan, au changement d'onglet et à intervalle régulier.
/// Les écrans qui proposent « tirer pour actualiser » ([AppPage.onRefresh]) se rechargent alors seuls.
class DataRefresh extends ChangeNotifier {
  DataRefresh._();

  static final DataRefresh instance = DataRefresh._();

  Timer? _debounce;

  /// Demande une actualisation. Plusieurs demandes rapprochées n'en produisent qu'une.
  void request() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), notifyListeners);
  }
}
