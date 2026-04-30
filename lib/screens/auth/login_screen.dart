import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/color_utils.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                      AppColors.primaryNeon.withOpacityValue(0.3),
                      AppColors.secondaryNeon.withOpacityValue(0.3),
                    ],
                  ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'QUESTIFY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNeon,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: AppStrings.email,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.email,
                        color: AppColors.primaryNeon),
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

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: AppStrings.password,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.lock,
                        color: AppColors.primaryNeon),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primaryNeon,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(
                        color: AppColors.primaryNeon,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
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
                            : () {
                                if (_emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text(AppStrings.errorEmptyField),
                                    ),
                                  );
                                  return;
                                }

                                authProvider.login(
                                  _emailController.text,
                                  _passwordController.text,
                                );
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
                                AppStrings.login,
                                style: TextStyle(
                                  color: AppColors.darkBg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.dontHaveAccount,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        AppStrings.register,
                        style: TextStyle(
                          color: AppColors.primaryNeon,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}