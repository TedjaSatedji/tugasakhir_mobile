import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/constants/app_themes.dart';
import 'core/constants/app_strings.dart';
import 'core/services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/quest_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/character_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/app_lock_screen.dart';
import 'screens/home/home_screen.dart';

import 'core/services/api_client.dart';
import 'services/local_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();

  // Hydrate the userId cache before providers load data
  await StorageService().initialize();
  
  // Initialize Local Notifications
  await LocalNotificationService().initialize();
  
  // Setup global auth failure hook
  ApiClient.onAuthFailed = () {
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      // We will let AuthProvider handle the UI redirection by calling logout()
      Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false).logout();
    }
  };
  
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('id'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id'),
      child: const MyApp(),
    ),
  );
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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppThemes.lightMinimalistTheme,
            darkTheme: AppThemes.darkCyberpunkTheme,
            themeMode: themeProvider.themeMode,
            navigatorKey: navigatorKey,
            home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isInitialized) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }

            if (authProvider.isLockEnabled && !authProvider.isUnlocked) {
              return const AppLockScreen();
            }

            return const HomeScreen();
          },
        ),
      );
    },
    ),
  );
}
}