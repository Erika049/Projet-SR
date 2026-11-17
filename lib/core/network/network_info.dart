/// Indique si l'appareil a accès au réseau.
/// À brancher sur `connectivity_plus` ou un ping de l'API.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implémentation de développement : en ligne par défaut, basculable
/// pour tester les écrans « Hors connexion ».
class SimulatedNetworkInfo implements NetworkInfo {
  bool online = true;

  @override
  Future<bool> get isConnected async => online;
}
