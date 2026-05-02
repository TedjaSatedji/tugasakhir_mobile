import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import 'transaction_detail_screen.dart';

class SpendingMapScreen extends StatefulWidget {
  const SpendingMapScreen({super.key});

  @override
  State<SpendingMapScreen> createState() => _SpendingMapScreenState();
}

class _SpendingMapScreenState extends State<SpendingMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Pengeluaran'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transProvider, _) {
          final located = transProvider.transactions
              .where((t) => t.latitude != null && t.longitude != null)
              .toList();

          if (located.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada transaksi dengan lokasi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan lokasi saat mencatat transaksi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          // Center map on the most recent located transaction
          final center = LatLng(
            located.first.latitude!,
            located.first.longitude!,
          );

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tugasakhir_mobile',
              ),
              MarkerLayer(
                markers: located.map((t) {
                  final isIncome = t.type == TransactionType.income;
                  final color = isIncome ? AppColors.success : AppColors.error;
                  return Marker(
                    point: LatLng(t.latitude!, t.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showTransactionSheet(context, t),
                      child: Icon(
                        Icons.location_pin,
                        color: color,
                        size: 36,
                        shadows: const [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTransactionSheet(BuildContext context, TransactionModel t) {
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final sign = isIncome ? '+' : '-';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(t.timestamp),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$sign Rp${NumberFormat('#,##0', 'en_US').format(t.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            if (t.locationName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.primaryNeon),
                  const SizedBox(width: 6),
                  Text(
                    t.locationName!,
                    style: const TextStyle(
                      color: AppColors.primaryNeon,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(transaction: t),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNeon,
                  side: const BorderSide(color: AppColors.primaryNeon),
                ),
                child: const Text('Lihat Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
