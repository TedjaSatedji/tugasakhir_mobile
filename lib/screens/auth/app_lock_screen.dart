import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/app_snackbar.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  late TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricOnOpen();
    });
  }

  Future<void> _tryBiometricOnOpen() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isBiometricUnlockEnabled) return;
    final success = await authProvider.unlockWithBiometric();
    if (!mounted) return;
    if (!success) {
      final message = authProvider.errorMessage ?? AppStrings.errorNetworkError;
      AppSnackbar.show(context, message: message, isError: false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock,
                color: AppColors.primaryNeon,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.unlockTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: AppStrings.pin,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.vpn_key, color: AppColors.primaryNeon),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryNeon,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryNeon,
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Column(
                    children: [
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
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  if (_pinController.text.length != 6) {
                                    AppSnackbar.show(context, message: AppStrings.pinHelper, isError: false);
                                    return;
                                  }

                                  final success = await authProvider.unlockWithPin(
                                    _pinController.text,
                                  );

                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (!success) {
                                    final message = authProvider.errorMessage ??
                                        AppStrings.errorNetworkError;
                                    AppSnackbar.show(context, message: message, isError: false);
                                  }
                                },
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.darkBg,
                                    ),
                                  ),
                                )
                              : const Text(
                                  AppStrings.unlock,
                                  style: TextStyle(
                                    color: AppColors.darkBg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (authProvider.isBiometricUnlockEnabled)
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  final success = await authProvider.unlockWithBiometric();

                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (!success) {
                                    final message = authProvider.errorMessage ??
                                        AppStrings.errorNetworkError;
                                    AppSnackbar.show(context, message: message, isError: false);
                                  }
                                },
                          child: const Text(
                            AppStrings.useBiometric,
                            style: TextStyle(
                              color: AppColors.primaryNeon,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
