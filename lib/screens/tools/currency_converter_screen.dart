import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController(text: '1');
  
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double _convertedAmount = 0.0;
  bool _isLoading = false;
  String _errorMessage = '';

  // Allowed currencies
  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'GBP', 'JPY', 'SGD', 'MYR', 'AUD'];

  // Cache for fetched rates for the current 'from' currency
  Map<String, dynamic> _currentRates = {};

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchRatesAndConvert();
  }

  Future<void> _fetchRatesAndConvert() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final String code = _fromCurrency.toLowerCase();
    final String primaryUrl = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$code.json';
    final String fallbackUrl = 'https://latest.currency-api.pages.dev/v1/currencies/$code.json';

    try {
      Response response;
      try {
        response = await _dio.get(primaryUrl);
      } catch (e) {
        // Fallback if primary fails
        response = await _dio.get(fallbackUrl);
      }

      if (response.statusCode == 200 && response.data != null) {
        _currentRates = response.data[code];
        _convert();
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data kurs.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Koneksi gagal. Periksa internet Anda.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _convert() {
    if (_currentRates.isEmpty) return;

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    
    // The rates map contains the multiplier from the base currency to the target currency
    final String targetCode = _toCurrency.toLowerCase();
    
    if (_fromCurrency == _toCurrency) {
      setState(() => _convertedAmount = amount);
      return;
    }

    if (_currentRates.containsKey(targetCode)) {
      double rate = (_currentRates[targetCode] as num).toDouble();
      setState(() {
        _convertedAmount = amount * rate;
      });
    } else {
      setState(() {
        _errorMessage = 'Mata uang tujuan tidak didukung.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konverter Mata Uang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Motivational Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryNeon.withOpacity(0.2),
                    AppColors.primaryNeon.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryNeon.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_exchange, color: AppColors.primaryNeon, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Siap Keliling Dunia?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Kurs mata uang real-time yang diperbarui setiap hari.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Amount Input
            const Text(
              'Jumlah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (val) => _convert(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryNeon),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Selectors
            Row(
              children: [
                Expanded(
                  child: _CurrencySelector(
                    label: 'Dari',
                    value: _fromCurrency,
                    currencies: _currencies,
                    onChanged: (val) {
                      if (val != null && val != _fromCurrency) {
                        setState(() {
                          _fromCurrency = val;
                        });
                        _fetchRatesAndConvert();
                      }
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz, color: AppColors.primaryNeon, size: 30),
                    onPressed: () {
                      setState(() {
                        final temp = _fromCurrency;
                        _fromCurrency = _toCurrency;
                        _toCurrency = temp;
                      });
                      _fetchRatesAndConvert();
                    },
                  ),
                ),
                Expanded(
                  child: _CurrencySelector(
                    label: 'Ke',
                    value: _toCurrency,
                    currencies: _currencies,
                    onChanged: (val) {
                      if (val != null && val != _toCurrency) {
                        setState(() {
                          _toCurrency = val;
                        });
                        _convert(); // Just recalculate since we already have the base rates
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Error Message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: AppColors.error, fontFamily: 'Poppins'),
                  textAlign: TextAlign.center,
                ),
              ),

            // Result
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryNeon.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryNeon),
                    )
                  : Column(
                      children: [
                        const Text(
                          'Hasil Konversi',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_toCurrency ${_convertedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNeon,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final String label;
  final String value;
  final List<String> currencies;
  final ValueChanged<String?> onChanged;

  const _CurrencySelector({
    required this.label,
    required this.value,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryNeon),
              items: currencies.map((c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
