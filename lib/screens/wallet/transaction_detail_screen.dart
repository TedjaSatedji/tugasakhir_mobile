import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';
import 'edit_transaction_screen.dart';
import '../../core/utils/app_snackbar.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currentTransaction = context.watch<TransactionProvider>().transactions
        .firstWhere(
          (t) => t.id == transaction.id,
          orElse: () => transaction,
        );
    final isIncome = currentTransaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final typeLabel = isIncome ? 'income'.tr() : 'expense'.tr();
    final sign = isIncome ? '+' : '-';

    return Scaffold(
      appBar: AppBar(
        title: Text('transactionDetail'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primaryNeon),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTransactionScreen(
                    transaction: currentTransaction,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: context.card,
                  title: Text(
                    'deleteTransactionTitle'.tr(),
                    style: TextStyle(
                      color: context.text,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  content: Text(
                    'deleteTransactionDesc'.tr(),
                    style: TextStyle(
                      color: context.textDim,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'cancel'.tr(),
                        style: TextStyle(color: context.textDim),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: Text(
                        'delete'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final xpToRemove = currentTransaction.xpAwarded > 0
                    ? currentTransaction.xpAwarded
                    : (currentTransaction.amount / 1000).floor();

                if (currentTransaction.missionCompletedId != null &&
                    currentTransaction.missionCompletedDateKey != null) {
                  await context.read<QuestProvider>().revokeDailyMission(
                        currentTransaction.missionCompletedId!,
                        currentTransaction.missionCompletedDateKey!,
                      );
                }

                if (xpToRemove > 0) {
                  await context.read<CharacterProvider>().removeXP(xpToRemove);
                }
                if (currentTransaction.coinsAwarded > 0) {
                  await context
                      .read<CharacterProvider>()
                      .removeCoins(currentTransaction.coinsAwarded);
                }
                await context
                    .read<TransactionProvider>()
                    .deleteTransaction(currentTransaction.id);
                Navigator.pop(context);
                AppSnackbar.show(context, message: 'transactionDeleted'.tr(), isError: false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$sign Rp${NumberFormat('#,##0', 'en_US').format(currentTransaction.amount)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.description,
                    label: 'description'.tr(),
                    value: currentTransaction.description.isEmpty
                        ? 'noDescription'.tr()
                        : currentTransaction.description,
                  ),
                  Divider(color: context.textDim, height: 30),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'date'.tr(),
                    value: DateFormat('dd MMMM yyyy, HH:mm')
                        .format(currentTransaction.timestamp),
                  ),
                  if (currentTransaction.category != null) ...[
                    Divider(color: context.textDim, height: 30),
                    _DetailRow(
                      icon: Icons.category,
                      label: 'category'.tr(),
                      value: _getCategoryLabel(currentTransaction.category!),
                    ),
                  ],
                  if (currentTransaction.detectedCategory != null &&
                      currentTransaction.detectedCategory!.isNotEmpty) ...[
                    Divider(color: context.textDim, height: 30),
                    _DetailRow(
                      icon: Icons.auto_fix_high,
                      label: 'aiCategory'.tr(),
                      value: currentTransaction.detectedCategory!,
                    ),
                  ],
                  if (currentTransaction.locationName != null &&
                      currentTransaction.locationName!.isNotEmpty) ...[
                    Divider(color: context.textDim, height: 30),
                    _DetailRow(
                      icon: Icons.location_on,
                      label: 'location'.tr(),
                      value: currentTransaction.locationName!,
                    ),
                  ],
                ],
              ),
            ),

            // Mini Map
            if (currentTransaction.latitude != null && currentTransaction.longitude != null) ...[
              const SizedBox(height: 25),
              Text(
                'transactionLocation'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: context.text,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        currentTransaction.latitude!,
                        currentTransaction.longitude!,
                      ),
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.tugasakhir_mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              currentTransaction.latitude!,
                              currentTransaction.longitude!,
                            ),
                            child: Icon(
                              Icons.location_pin,
                              color: color,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Receipt Image
            if (currentTransaction.receiptImageUrl != null &&
                currentTransaction.receiptImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 25),
              Text(
                'receiptPhoto'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: context.text,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: currentTransaction.receiptImageUrl!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: currentTransaction.receiptImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: context.card,
                        child: Center(child: CircularProgressIndicator(color: context.primary)),
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: context.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: context.textDim,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'imageNotAvailable'.tr(),
                                  style: TextStyle(
                                    color: context.textDim,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(transaction.receiptImageUrl!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: context.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: context.textDim,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'imageNotAvailable'.tr(),
                                  style: TextStyle(
                                    color: context.textDim,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Makanan';
      case ExpenseCategory.fashion:
        return 'Fashion';
      case ExpenseCategory.hobby:
        return 'Hobi';
      case ExpenseCategory.transport:
        return 'Transportasi';
      case ExpenseCategory.health:
        return 'Kesehatan';
      case ExpenseCategory.education:
        return 'Pendidikan';
      case ExpenseCategory.entertainment:
        return 'Hiburan';
      case ExpenseCategory.other:
        return 'Lainnya';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textDim,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: context.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
