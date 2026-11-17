import 'package:intl/intl.dart';

/// Formats d'affichage utilisés dans les maquettes (français).
abstract final class Formatters {
  static final _amount = NumberFormat.decimalPattern('fr_FR');

  /// 45000 → « 45 000 FCFA »
  static String fcfa(num value) => '${number(value)} FCFA';

  /// 45000 → « 45 000 »
  static String number(num value) => _amount.format(value).replaceAll(' ', ' ').replaceAll(' ', ' ');

  /// 14.6 → « 14,6 »
  static String grade(num value, {int decimals = 1}) => value.toStringAsFixed(decimals).replaceAll('.', ',');

  /// Lundi 9 novembre 2026
  static String longDate(DateTime d, {bool withYear = true}) =>
      _capitalize(DateFormat(withYear ? 'EEEE d MMMM y' : 'EEEE d MMMM', 'fr_FR').format(d));

  /// 05 sept. 2026
  static String shortDate(DateTime d) => DateFormat('dd MMM y', 'fr_FR').format(d);

  /// 09 NOV.
  static String dayMonthUpper(DateTime d) => DateFormat('dd MMM', 'fr_FR').format(d).toUpperCase();

  /// 08:15
  static String time(DateTime d) => DateFormat('HH:mm').format(d);

  /// 8 → « 08 H », 8:15 → « 08 H 15 »
  static String hour(DateTime d) => d.minute == 0 ? '${_two(d.hour)} H' : '${_two(d.hour)} H ${_two(d.minute)}';

  /// « 08 H – 09 H »
  static String slot(DateTime start, DateTime end) => '${hour(start)} – ${hour(end)}';

  /// Novembre 2026
  static String monthYear(DateTime d) => _capitalize(DateFormat('MMMM y', 'fr_FR').format(d));

  /// 5 → « 5e », 1 → « 1er »
  static String rank(int r) => r == 1 ? '1er' : '${r}e';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
