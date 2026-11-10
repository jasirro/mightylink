import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/group.dart';
import 'models/saved_link.dart';
import 'screens/splash_screen.dart';
import 'services/db_service.dart';
import 'services/dashboard_service.dart';
import 'services/google_drive_sync_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
  
  await DashboardService.init();
  await GoogleDriveSyncService.init();
  
  runApp(const LinkNestApp());
}

class LinkNestApp extends StatefulWidget {
  const LinkNestApp({super.key});

  @override
  State<LinkNestApp> createState() => _LinkNestAppState();
}

class _LinkNestAppState extends State<LinkNestApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GoogleDriveSyncService.triggerAutoSync(reason: 'app_resumed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mightylink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.primaryViolet,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryViolet,
          primary: AppColors.primaryViolet,
          secondary: AppColors.accentYellow,
          tertiary: AppColors.fabGreen,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentYellow,
            foregroundColor: AppColors.yellowButtonText,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputPurpleFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputPurpleBorder, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputPurpleBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.inputPurpleBorderFocused, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textOnPurpleMuted),
          hintStyle: const TextStyle(color: AppColors.textOnPurpleMuted),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleMedium: TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: AppColors.textOnPurpleMuted),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
