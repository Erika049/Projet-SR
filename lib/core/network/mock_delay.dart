/// Simule la latence réseau dans les datasources « mock ».
Future<void> mockDelay([int ms = 450]) => Future.delayed(Duration(milliseconds: ms));
