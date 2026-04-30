import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;
  String _selectedTheme = 'dark';
  String _selectedLanguage = 'id';

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
              title: 'Aktifkan Notifikasi',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 30),

            // Security Section
            _SectionTitle(title: 'Keamanan'),
            const SizedBox(height: 15),
            _SwitchTile(
              title: 'Biometric Login',
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() {
                  _biometricEnabled = value;
                });
              },
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
  final ValueChanged<bool> onChanged;

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