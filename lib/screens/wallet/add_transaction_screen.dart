import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/receipt_ai_service.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  TransactionType _selectedType = TransactionType.expense;
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  final ImagePicker _imagePicker = ImagePicker();
  String? _receiptImagePath;
  bool _isScanning = false;
  final ReceiptAiService _receiptAiService = ReceiptAiService();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selection
            const Text(
              'Tipe Transaksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: AppStrings.income,
                    isSelected: _selectedType == TransactionType.income,
                    color: AppColors.success,
                    onTap: () {
                      setState(() {
                        _selectedType = TransactionType.income;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeButton(
                    label: AppStrings.expense,
                    isSelected: _selectedType == TransactionType.expense,
                    color: AppColors.error,
                    onTap: () {
                      setState(() {
                        _selectedType = TransactionType.expense;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Amount
            const Text(
              'Jumlah (Rp)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan deskripsi transaksi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryNeon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Foto (Opsional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickReceiptImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryNeon,
                      side: const BorderSide(color: AppColors.primaryNeon),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _scanReceipt,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(_isScanning ? 'Memindai...' : 'Scan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryNeon,
                      side: const BorderSide(color: AppColors.secondaryNeon),
                    ),
                  ),
                ),
                if (_receiptImagePath != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _receiptImagePath = null;
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
            if (_receiptImagePath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_receiptImagePath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Category (for expense only)
            if (_selectedType == TransactionType.expense) ...[
              const Text(
                AppStrings.expenseCategory,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<ExpenseCategory>(
                value: _selectedCategory,
                isExpanded: true,
                items: ExpenseCategory.values
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (_amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jumlah tidak boleh kosong'),
                      ),
                    );
                    return;
                  }

                  final amount = double.tryParse(_amountController.text) ?? 0;
                  final category = _selectedType == TransactionType.expense
                      ? _selectedCategory
                      : null;

                  await context.read<TransactionProvider>().addTransaction(
                    _selectedType,
                    category,
                    amount,
                    _descriptionController.text.isEmpty
                        ? 'Transaksi'
                        : _descriptionController.text,
                    _receiptImagePath,
                  );

                    await context.read<CharacterProvider>().addXpForAmount(amount);

                    // Complete daily mission and award its XP
                  final missionXp = await context
                      .read<QuestProvider>()
                      .completeDailyMission('mission_1');
                  if (missionXp > 0) {
                    await context.read<CharacterProvider>().addXP(missionXp);
                  }

                  // Show Notification
                  context.read<NotificationProvider>().addNotification(
                    NotificationModel(
                      title: 'Transaksi Berhasil',
                      message: 'Kamu mendapatkan +10 XP!',
                      type: NotificationType.transaction,
                    ),
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          AppStrings.successAddTransactionMessage),
                    ),
                  );
                },
                child: const Text(
                  'Simpan Transaksi',
                  style: TextStyle(
                    color: AppColors.darkBg,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _receiptImagePath = image.path;
    });
  }

  Future<void> _scanReceipt() async {
    if (_receiptImagePath == null || _receiptImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final result = await _receiptAiService.extractFromImage(
        _receiptImagePath!,
      );

      if (result.amount != null) {
        _amountController.text = result.amount!.toStringAsFixed(0);
      }

      if (result.description != null && result.description!.isNotEmpty) {
        _descriptionController.text = result.description!;
      }

      if (result.type != null && result.type!.isNotEmpty) {
        final type = result.type!.toLowerCase();
        if (type == 'income' || type == 'expense') {
          _selectedType =
              type == 'income' ? TransactionType.income : TransactionType.expense;
        }
      }

      if (result.category != null && result.category!.isNotEmpty) {
        final category = _mapCategory(result.category!);
        if (category != null) {
          _selectedCategory = category;
        }
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data otomatis terisi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  ExpenseCategory? _mapCategory(String raw) {
    final normalized = raw.toLowerCase().trim();
    for (final category in ExpenseCategory.values) {
      if (category.name.toLowerCase() == normalized) {
        return category;
      }
    }
    return null;
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.textSecondary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}