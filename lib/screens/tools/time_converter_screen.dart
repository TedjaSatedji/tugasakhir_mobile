import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';

class TimeConverterScreen extends StatefulWidget {
  const TimeConverterScreen({super.key});

  @override
  State<TimeConverterScreen> createState() => _TimeConverterScreenState();
}

class _TimeConverterScreenState extends State<TimeConverterScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now().toUtc();

  final List<Map<String, dynamic>> _timeZones = [
    {
      'name': 'WIB (Jakarta)',
      'offset': 7,
      'market': 'indonesiaStockExchange',
      'icon': Icons.location_city,
    },
    {
      'name': 'WITA (Bali)',
      'offset': 8,
      'market': 'centralDomesticMarket',
      'icon': Icons.landscape,
    },
    {
      'name': 'WIT (Papua)',
      'offset': 9,
      'market': 'easternDomesticMarket',
      'icon': Icons.forest,
    },
    {
      'name': 'GMT (London)',
      'offset': 0,
      'market': 'London Stock Exchange',
      'icon': Icons.account_balance,
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now().toUtc();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time, int offset) {
    final localTime = time.add(Duration(hours: offset));
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final second = localTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _formatDate(DateTime time, int offset) {
    final localTime = time.add(Duration(hours: offset));
    final day = localTime.day.toString().padLeft(2, '0');
    final month = localTime.month.toString().padLeft(2, '0');
    final year = localTime.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('globalTimeTitle'.tr()),
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
                    AppColors.secondaryNeon.withOpacity(0.2),
                    AppColors.secondaryNeon.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.secondaryNeon.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public, color: AppColors.secondaryNeon, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'monitorGlobalMarket'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'globalMarketDesc'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textDim,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Time Zones List
            ..._timeZones.map((tz) => _buildTimeZoneCard(context, tz)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeZoneCard(BuildContext context, Map<String, dynamic> tz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.textDim.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(tz['icon'], color: context.primary, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tz['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: context.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tz['market'].toString().tr(),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textDim,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(_currentTime, tz['offset']),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(_currentTime, tz['offset']),
                style: TextStyle(
                  fontSize: 10,
                  color: context.textDim,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
