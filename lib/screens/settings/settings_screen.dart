import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_notification_service.dart';
import '../games/budget_invaders_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  String _selectedTheme = 'dark';
  String _selectedLanguage = 'id';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      final hour = prefs.getInt('daily_reminder_hour') ?? 20;
      final minute = prefs.getInt('daily_reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', _dailyReminderEnabled);
    await prefs.setInt('daily_reminder_hour', _reminderTime.hour);
    await prefs.setInt('daily_reminder_minute', _reminderTime.minute);

    if (_dailyReminderEnabled) {
      await LocalNotificationService().scheduleDailyReminder(_reminderTime);
    } else {
      await LocalNotificationService().cancelReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Section
            _SectionTitle(title: 'Display'),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'Tema',
              value: _selectedTheme,
              onTap: () {
                _showThemeDialog();
              },
            ),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'Bahasa',
              value: _selectedLanguage,
              onTap: () {
                _showLanguageDialog();
              },
            ),
            const SizedBox(height: 30),

            // Notification Section
            _SectionTitle(title: 'Notifikasi'),
            const SizedBox(height: 15),
            _SwitchTile(
              title: 'Pengingat Harian (Lokal)',
              value: _dailyReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _dailyReminderEnabled = value;
                });
                _saveSettings();
              },
            ),
            if (_dailyReminderEnabled) ...[
              const SizedBox(height: 15),
              _SettingTile(
                title: 'Waktu Pengingat',
                value: '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _reminderTime = picked;
                    });
                    _saveSettings();
                  }
                },
              ),
            ],
            const SizedBox(height: 30),

            // Security Section
            _SectionTitle(title: 'Keamanan'),
            const SizedBox(height: 15),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  children: [
                    _SwitchTile(
                      title: AppStrings.enableQuickUnlock,
                      value: authProvider.isLockEnabled,
                      onChanged: (value) {
                        if (value) {
                          _showSetPinDialog(context);
                        } else {
                          authProvider.disableQuickUnlock();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: AppStrings.enableBiometricUnlock,
                      value: authProvider.isBiometricUnlockEnabled,
                      onChanged: authProvider.isLockEnabled
                          ? (value) {
                              authProvider.setBiometricUnlockEnabled(value);
                            }
                          : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            // Mini Games Section
            _SectionTitle(title: '🎮 Mini Games'),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetInvadersScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('💰', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budget Invaders',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: AppColors.primaryNeon,
                              )),
                          SizedBox(height: 3),
                          Text('Lindungi tabunganmu dari serangan pengeluaran!',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // About Section
            _SectionTitle(title: 'Tentang'),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'Versi App',
              value: '1.0.0',
              onTap: () {},
            ),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'Kebijakan Privasi',
              value: '',
              onTap: () {},
            ),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'Saran & Kesan',
              value: '',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Light'),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Bahasa Indonesia'),
              value: 'id',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('English'),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetPinDialog(BuildContext context) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const _PinDialog(),
    );

    if (pin == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.enableQuickUnlock(
      pin: pin,
      enableBiometric: authProvider.isBiometricUnlockEnabled,
    );

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pinSetSuccess)),
      );
    } else {
      final message = authProvider.errorMessage ?? AppStrings.errorNetworkError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late TextEditingController _pinController;
  late TextEditingController _confirmController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.setPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: AppStrings.pin,
                helperText: AppStrings.pinHelper,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: AppStrings.confirmPin,
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            final confirm = _confirmController.text.trim();

            if (pin.length != 6 || confirm.length != 6) {
              setState(() {
                _errorText = AppStrings.pinHelper;
              });
              return;
            }

            if (pin != confirm) {
              setState(() {
                _errorText = AppStrings.pinMismatch;
              });
              return;
            }

            Navigator.pop(context, pin);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        color: AppColors.primaryNeon,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryNeon.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryNeon.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryNeon,
          ),
        ],
      ),
    );
  }
}