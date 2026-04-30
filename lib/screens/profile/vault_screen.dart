import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final AuthService _authService = AuthService();
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isUnlocked ? Icons.lock_open : Icons.lock,
              size: 100,
              color: _isUnlocked ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 30),
            Text(
              _isUnlocked ? 'Vault Terbuka' : 'Vault Terkunci',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            if (!_isUnlocked)
              Text(
                'Gunakan biometric untuk membuka vault',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: 150,
              height: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  shape: const CircleBorder(),
                ),
                onPressed: () async {
                  final isAuthenticated =
                      await _authService.authenticateWithBiometric();
                  if (isAuthenticated) {
                    setState(() {
                      _isUnlocked = true;
                    });
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isUnlocked ? Icons.check_circle : Icons.fingerprint,
                      size: 60,
                      color: AppColors.darkBg,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isUnlocked ? 'Berhasil' : AppStrings.unlockVault,
                      style: const TextStyle(
                        color: AppColors.darkBg,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isUnlocked) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryNeon.withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Konten Vault',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Catatan pribadi, file penting, dan data sensitif disimpan di sini dengan enkripsi tingkat tinggi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}