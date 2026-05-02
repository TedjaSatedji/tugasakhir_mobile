import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_notification_service.dart';
import '../games/budget_invaders_screen.dart';
import '../../core/extensions/theme_extensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

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
        title: Text('settingsTitle'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Section
            _SectionTitle(title: 'display'.tr()),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'theme'.tr(),
              value: context.watch<ThemeProvider>().isDarkMode ? 'dark'.tr() : 'light'.tr(),
              onTap: () {
                _showThemeDialog();
              },
            ),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'language'.tr(),
              value: context.locale.languageCode == 'id' ? 'Bahasa Indonesia' : 'English',
              onTap: () {
                _showLanguageDialog();
              },
            ),
            const SizedBox(height: 30),

            // Notification Section
            _SectionTitle(title: 'notification'.tr()),
            const SizedBox(height: 15),
            _SwitchTile(
              title: 'dailyReminder'.tr(),
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
                title: 'reminderTime'.tr(),
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
            _SectionTitle(title: 'security'.tr()),
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
                  color: context.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('💰', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budget Invaders',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: context.primary,
                              )),
                          const SizedBox(height: 3),
                          Text('budgetInvadersDesc'.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textDim,
                                fontFamily: 'Poppins',
                              )),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: context.textDim),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // About Section
            _SectionTitle(title: 'about'.tr()),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'appVersion'.tr(),
              value: '1.0.0',
              onTap: () {},
            ),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'privacyPolicy'.tr(),
              value: '',
              onTap: () {
                _showPrivacyPolicyDialog();
              },
            ),
            const SizedBox(height: 15),
            _SettingTile(
              title: 'feedback'.tr(),
              value: '',
              onTap: () {
                _showFeedbackDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.card,
        title: Text('selectTheme'.tr(), style: TextStyle(color: context.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: Text('dark'.tr(), style: TextStyle(color: context.text)),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
              activeColor: context.primary,
            ),
            RadioListTile(
              title: Text('light'.tr(), style: TextStyle(color: context.text)),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
              activeColor: context.primary,
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
        backgroundColor: context.card,
        title: Text('selectLanguage'.tr(), style: TextStyle(color: context.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: Text('Bahasa Indonesia', style: TextStyle(color: context.text)),
              value: 'id',
              groupValue: context.locale.languageCode,
              onChanged: (value) {
                context.setLocale(Locale(value!));
                Navigator.pop(context);
              },
              activeColor: context.primary,
            ),
            RadioListTile(
              title: Text('English', style: TextStyle(color: context.text)),
              value: 'en',
              groupValue: context.locale.languageCode,
              onChanged: (value) {
                context.setLocale(Locale(value!));
                Navigator.pop(context);
              },
              activeColor: context.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.card,
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: context.primary),
            const SizedBox(width: 10),
            Text('privacyPolicy'.tr(), style: TextStyle(color: context.text, fontFamily: 'Poppins', fontSize: 18)),
          ],
        ),
        content: Text(
          'privacyText'.tr(),
          style: TextStyle(color: context.textDim, fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('gotIt'.tr(), style: TextStyle(color: context.primary, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.card,
        title: Row(
          children: [
            Icon(Icons.favorite, color: AppColors.error),
            const SizedBox(width: 10),
            Text('feedback'.tr(), style: TextStyle(color: context.text, fontFamily: 'Poppins', fontSize: 18)),
          ],
        ),
        content: Text(
          'feedbackText'.tr(),
          style: TextStyle(color: context.textDim, fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(), style: TextStyle(color: context.textDim, fontFamily: 'Poppins')),
          ),
        ],
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
          child: Text('cancel'.tr()),
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
          child: Text('save'.tr()),
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        color: context.primary,
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
          color: context.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: context.text,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: context.textDim,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.textDim,
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
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: context.text,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.primary,
          ),
        ],
      ),
    );
  }
}