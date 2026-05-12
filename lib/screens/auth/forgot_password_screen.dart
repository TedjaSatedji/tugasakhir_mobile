import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/theme_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import 'verify_reset_code_screen.dart';
import '../../core/utils/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.forgotPasswordTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: AppStrings.email,
                  hintStyle: TextStyle(color: context.textDim),
                  prefixIcon: Icon(Icons.email, color: context.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.primary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(color: context.text),
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_emailController.text.isEmpty) {
                                AppSnackbar.show(context, message: AppStrings.errorEmptyField, isError: true);
                                return;
                              }

                              final success = await authProvider.requestPasswordReset(
                                _emailController.text,
                              );

                              if (!context.mounted) {
                                return;
                              }

                              if (success) {
                                AppSnackbar.show(context, message: AppStrings.resetRequestSentCode, isError: false);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerifyResetCodeScreen(
                                      email: _emailController.text,
                                    ),
                                  ),
                                );
                              } else {
                                final message = authProvider.errorMessage ??
                                    AppStrings.errorNetworkError;
                                AppSnackbar.show(context, message: message, isError: false);
                              }
                            },
                      child: authProvider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.bg,
                                ),
                              ),
                            )
                          : Text(
                              AppStrings.resetPassword,
                              style: TextStyle(
                                color: context.bg,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
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
