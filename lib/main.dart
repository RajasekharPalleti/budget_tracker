import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/budget_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce Edge-to-Edge with transparent bars and dark icons by default (for light theme)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Dark icons for light background
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await NotificationService().init();
  
  final userProvider = UserProvider();
  await userProvider.loadUserData();

  final budgetProvider = BudgetProvider();
  await budgetProvider.loadData();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => budgetProvider),
        ChangeNotifierProvider(create: (_) => userProvider),
      ],
      child: const BudgetTrackerApp(),
    ),
  );
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Use Light mode for the new design system
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return userProvider.isFirstLaunch 
              ? const OnboardingScreen() 
              : const HomeScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
