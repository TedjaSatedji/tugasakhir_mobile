import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/location_service.dart';
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
  DateTime _selectedDate = DateTime.now();
  final ImagePicker _imagePicker = ImagePicker();
  String? _receiptImagePath;
  bool _isScanning = false;
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  final ReceiptAiService _receiptAiService = ReceiptAiService();
  final LocationService _locationService = LocationService();

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
        title: Text('addTransaction'.tr()),
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
            Text(
              'transactionType'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
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
            Text(
              'amountRp'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.text),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: context.textDim),
                prefixText: 'Rp ',
                prefixStyle: TextStyle(color: context.text),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              'description'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(color: context.text),
              decoration: InputDecoration(
                hintText: 'noDescription'.tr(),
                hintStyle: TextStyle(color: context.textDim),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date Picker
            Text(
              'date'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: context.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: context.text),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: context.textDim),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'optionalPhoto'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickReceiptImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text('pickPhoto'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primary,
                      side: BorderSide(color: context.primary),
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
                    label: Text(_isScanning ? 'scanning'.tr() : 'scan'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      side: BorderSide(color: Theme.of(context).colorScheme.secondary),
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
              Text(
                'category'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: context.text,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<ExpenseCategory>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: context.card,
                style: TextStyle(color: context.text, fontFamily: 'Poppins'),
                items: ExpenseCategory.values
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category.name.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: context.text,
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

            // Location Button
            Text(
              'optionalLocation'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            const SizedBox(height: 10),
            if (_locationName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationName!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      onPressed: () => setState(() {
                        _latitude = null;
                        _longitude = null;
                        _locationName = null;
                      }),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _isLocating ? null : _captureLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLocating ? 'gettingLocation'.tr() : 'addLocation'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primary,
                  side: BorderSide(color: context.primary),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            const SizedBox(height: 20),

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
                      SnackBar(
                        content: Text('amountCannotBeEmpty'.tr()),
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
                    timestamp: _selectedDate,
                    latitude: _latitude,
                    longitude: _longitude,
                    locationName: _locationName,
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
                    SnackBar(
                      content: Text('transactionSuccess'.tr()),
                    ),
                  );
                },
                child: Text(
                  'saveTransaction'.tr(),
                  style: TextStyle(
                    color: context.bg,
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
      maxWidth: 1024,
      imageQuality: 70,
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
        SnackBar(content: Text('selectPhotoFirst'.tr())),
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
        SnackBar(content: Text('autoFilled'.tr())),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.primary,
              onPrimary: context.bg,
              surface: context.card,
              onSurface: context.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('cannotGetLocation'.tr())),
          );
        }
        return;
      }

      final name = await _locationService.getPlaceName(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
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
          color: isSelected ? color.withOpacity(0.2) : context.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.textDim,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : context.textDim,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}