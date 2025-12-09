import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currency = 'XOF'}) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
