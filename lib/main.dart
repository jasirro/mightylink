import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/group.dart';
import 'models/saved_link.dart';
import 'screens/splash_screen.dart';
import 'services/db_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(SavedLinkAdapter());
  
  final authBox = await Hive.openBox('auth');
  final isLoggedIn = authBox.get('isLoggedIn', defaultValue: false);
  final currentUser = authBox.get('currentUser', defaultValue: '') as String;
  
  if (isLoggedIn && currentUser.isNotEmpty) {
    DbService.activeUser = currentUser;
    await DbService.openUserBoxes(currentUser);
  }
  
  runApp(const LinkNestApp());
}

class LinkNestApp extends StatelessWidget {
  const LinkNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'linku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavy,
          surface: Colors.white,
          primary: AppColors.primaryNavy,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.primaryNavy),
          titleTextStyle: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primaryNavy,
          unselectedItemColor: AppColors.navInactive,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.subtitle),
          hintStyle: const TextStyle(color: AppColors.subtitle),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          titleLarge: TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleMedium: TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.cardTitle),
          bodyMedium: TextStyle(color: AppColors.cardTitle),
          bodySmall: TextStyle(color: AppColors.subtitle),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
