import 'package:flutter/material.dart';

import 'pill_selector.dart';
import 'status_chip.dart';

/// Bandeau d'information pleine largeur
/// (« Hors connexion · brouillon local », « Push et SMS activés »).
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.message, {super.key, this.tone = StatusTone.warning});

  /// Bandeau ambre affiché quand les données viennent du cache local.
  const InfoBanner.offline(this.message, {super.key}) : tone = StatusTone.warning;

  final String message;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: tone.background, borderRadius: cardRadius),
      child: Text(
        message,
        style: TextStyle(color: tone.foreground, fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}
