class CurrencyConverter {
  static const Map<String, double> exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000063,
    'JPY': 0.0094,
    'KWR': 0.00078,
    'EUR': 0.000059,
  };

  static double convert(double amount, String from, String to) {
    if (from == to) return amount;
    
    double rateFrom = exchangeRates[from] ?? 1.0;
    double rateTo = exchangeRates[to] ?? 1.0;
    
    return (amount / rateFrom) * rateTo;
  }

  static String formatCurrency(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}