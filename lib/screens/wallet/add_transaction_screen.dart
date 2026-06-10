import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/location_service.dart';
import '../../core/services/receipt_ai_service.dart';
import '../../core/services/api_client.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/coin_reward_overlay.dart';
import '../../core/utils/app_snackbar.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const int _maxAmountDigits = 15;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  TransactionType _selectedType = TransactionType.expense;
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();
  final ImagePicker _imagePicker = ImagePicker();
  String? _receiptImagePath;
  bool _isScanning = false;
  bool _isPredictingCategory = false;
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
                    label: 'income'.tr(),
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
                    label: 'expense'.tr(),
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
              inputFormatters: [
                _CurrencyInputFormatter(maxDigits: _maxAmountDigits),
              ],
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
                suffixIcon: IconButton(
                  icon: _isPredictingCategory 
                      ? const SizedBox(
                          width: 16, height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.amber),
                  onPressed: _isPredictingCategory ? null : _predictCategory,
                  tooltip: "Tebak Kategori Cerdas",
                ),
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
                OutlinedButton(
                  onPressed: _pickReceiptImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primary,
                    side: BorderSide(color: context.primary),
                  ),
                  child: const Icon(Icons.photo_library),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _captureReceiptImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primary,
                    side: BorderSide(color: context.primary),
                  ),
                  child: const Icon(Icons.photo_camera),
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
                    AppSnackbar.show(context, message: 'amountCannotBeEmpty'.tr(), isError: true);
                    return;
                  }

                  final rawAmount = _amountController.text.replaceAll(',', '');
                  final amount = double.tryParse(rawAmount) ?? 0;

                  if (amount <= 0) {
                    AppSnackbar.show(context, message: 'amountCannotBeZero'.tr(), isError: true);
                    return;
                  }

                  final category = _selectedType == TransactionType.expense
                      ? _selectedCategory
                      : null;

                    final questProvider = context.read<QuestProvider>();
                    final dateKey = questProvider.todayKey();

                    final (missionXp, missionCoins) =
                      await questProvider.completeDailyMission('mission_1');
                    final amountXp = (amount / 1000).floor();
                    final xpAwarded = amountXp + missionXp;
                    final totalCoins = 2 + missionCoins;

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
                    xpAwarded: xpAwarded,
                    coinsAwarded: totalCoins,
                    missionCompletedId: missionXp > 0 ? 'mission_1' : null,
                    missionCompletedDateKey: missionXp > 0 ? dateKey : null,
                  );

                  if (xpAwarded > 0) {
                    await context.read<CharacterProvider>().addXP(xpAwarded);
                  }

                  // Award +2 coins for logging a transaction
                  await context.read<CharacterProvider>().addCoins(totalCoins);
                  if (context.mounted) {
                    CoinRewardOverlay.show(context, totalCoins);
                  }

                  // Show Notification
                  context.read<NotificationProvider>().addNotification(
                    NotificationModel(
                      title: 'Transaksi Berhasil',
                      message: 'Kamu mendapatkan +$xpAwarded XP!',
                      type: NotificationType.transaction,
                    ),
                  );

                  Navigator.pop(context);
                  AppSnackbar.show(context, message: 'transactionSuccess'.tr(), isError: false);
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

  Future<void> _captureReceiptImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
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
      AppSnackbar.show(context, message: 'selectPhotoFirst'.tr(), isError: false);
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

      final parsedDate = _parseReceiptDate(result.date);
      if (parsedDate != null) {
        _selectedDate = parsedDate;
      }

      setState(() {});
      AppSnackbar.show(context, message: 'autoFilled'.tr(), isError: false);
    } catch (e) {
      AppSnackbar.show(context, message: e.toString(), isError: false);
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

  DateTime? _parseReceiptDate(String? raw) {
    if (raw == null) {
      return null;
    }

    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final normalized = _normalizeMonthNames(cleaned);
    DateTime? parsed = DateTime.tryParse(normalized);

    final candidates = <String>[normalized];
    final patterns = <RegExp>[
      RegExp(r'\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b'),
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      RegExp(r'\b\d{1,2}\s+[a-zA-Z]{3,9}\s+\d{2,4}\b'),
      RegExp(r'\b[a-zA-Z]{3,9}\s+\d{1,2},?\s+\d{2,4}\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        candidates.add(match.group(0)!);
      }
    }

    for (final candidate in candidates) {
      parsed ??= _parseWithFormats(candidate);
      if (parsed != null) {
        break;
      }
    }

    if (parsed == null) {
      return null;
    }

    final now = DateTime.now();
    if (parsed.isAfter(now.add(const Duration(days: 1)))) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? _parseWithFormats(String value) {
    const formats = <String>[
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'MM-dd-yyyy',
      'MM/dd/yyyy',
      'dd-MM-yy',
      'dd/MM/yy',
      'MM-dd-yy',
      'MM/dd/yy',
      'dd MMM yyyy',
      'dd MMMM yyyy',
      'MMM dd yyyy',
      'MMMM dd yyyy',
      'dd MMM yy',
      'dd MMMM yy',
      'MMM dd yy',
      'MMMM dd yy',
      'dd MMM yyyy HH:mm',
      'dd MMMM yyyy HH:mm',
      'yyyy-MM-dd HH:mm',
      'yyyy/MM/dd HH:mm',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format, 'en_US').parseStrict(value);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String _normalizeMonthNames(String text) {
    var normalized = text;
    const monthMap = <String, String>{
      'januari': 'jan',
      'january': 'jan',
      'februari': 'feb',
      'february': 'feb',
      'maret': 'mar',
      'march': 'mar',
      'april': 'apr',
      'mei': 'may',
      'may': 'may',
      'juni': 'jun',
      'june': 'jun',
      'juli': 'jul',
      'july': 'jul',
      'agustus': 'aug',
      'august': 'aug',
      'september': 'sep',
      'oktober': 'oct',
      'october': 'oct',
      'november': 'nov',
      'desember': 'dec',
      'december': 'dec',
    };

    monthMap.forEach((key, value) {
      normalized = normalized.replaceAll(
        RegExp(r'\b' + key + r'\b', caseSensitive: false),
        value,
      );
    });
    return normalized;
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

  Future<void> _predictCategory() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(context, message: 'Masukkan deskripsi terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isPredictingCategory = true);
    try {
      final response = await ApiClient().dio.post('/ml/predict-category', data: {
        'description': text,
      });
      final categoryInt = response.data['category'] as int?;
      if (categoryInt != null && categoryInt >= 0 && categoryInt < ExpenseCategory.values.length) {
        setState(() {
          _selectedCategory = ExpenseCategory.values[categoryInt];
          _selectedType = TransactionType.expense; // Usually if it has a category it's an expense
        });
        if (mounted) {
          AppSnackbar.show(context, message: 'Kategori ditebak: ${_selectedCategory.name}', isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Gagal menebak kategori', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPredictingCategory = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          AppSnackbar.show(context, message: 'cannotGetLocation'.tr(), isError: true);
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
        AppSnackbar.show(context, message: 'Gagal mendapatkan lokasi: $e', isError: true);
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

class _CurrencyInputFormatter extends TextInputFormatter {
  _CurrencyInputFormatter({required this.maxDigits});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final trimmed = digitsOnly.length > maxDigits
        ? digitsOnly.substring(0, maxDigits)
        : digitsOnly;
    final formatted =
        NumberFormat.decimalPattern('en_US').format(int.parse(trimmed));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}