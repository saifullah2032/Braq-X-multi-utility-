import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/permission_service.dart';

/// BARQ X Root Widget
class BARQXApp extends StatefulWidget {
  final bool showOnboarding;

  const BARQXApp({
    super.key,
    this.showOnboarding = false,
  });

  @override
  State<BARQXApp> createState() => _BARQXAppState();
}

class _BARQXAppState extends State<BARQXApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _completeOnboarding() async {
    // Request permissions
    await PermissionService.checkAndRequestPermissions();
    
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);
    
    // Navigate to home
    if (mounted) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BARQ X',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.accentPrimary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          headlineLarge: GoogleFonts.bebasNeue(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          headlineMedium: GoogleFonts.bebasNeue(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          headlineSmall: GoogleFonts.bebasNeue(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          titleLarge: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyMedium: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          bodySmall: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(
                color: AppColors.borderColor,
                width: 2,
              ),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.bebasNeue(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      home: _showOnboarding
           ? OnboardingScreen(onComplete: _completeOnboarding)
           : const HomeScreen(),
    );
  }
}
