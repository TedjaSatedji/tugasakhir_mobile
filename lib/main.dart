import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_themes.dart';
import 'core/constants/app_strings.dart';
import 'providers/auth_provider.dart';
import 'providers/quest_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/character_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuestProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppThemes.darkCyberpunkTheme,
        darkTheme: AppThemes.darkCyberpunkTheme,
        themeMode: ThemeMode.dark,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}