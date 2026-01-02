import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p_tracker/core/theme/theme_provider.dart';
import 'package:p_tracker/features/onboarding/presentation/utils/onboarding_constants.dart';
import 'package:p_tracker/features/onboarding/presentation/widgets/onboarding_step_one.dart';
import 'package:p_tracker/features/onboarding/presentation/widgets/onboarding_step_two.dart';
import 'package:p_tracker/features/onboarding/presentation/widgets/onboarding_step_three.dart';
import 'package:p_tracker/features/home/presentation/pages/home_page.dart';
import 'package:p_tracker/core/database/database_helper.dart';
import 'package:p_tracker/features/onboarding/data/models/user_settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  int _cycleLength = 28;
  int _periodDuration = 5;
  DateTime? _selectedDate = DateTime.now();

  void _toggleTheme(bool isDark) {
    ref.read(themeProvider.notifier).toggleTheme(!isDark);
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final bgColor = isDark ? OnboardingColors.bgDark : OnboardingColors.bgLight;
    final textMain = isDark
        ? OnboardingColors.textMainDark
        : OnboardingColors.textMainLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo / Brand
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: OnboardingColors.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "FlowTrack",
                        style: GoogleFonts.nunitoSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                    ],
                  ),

                  // Theme Toggle
                  IconButton(
                    onPressed: () => _toggleTheme(isDark),
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildProgressDot(0, isDark),
                  _buildProgressDot(1, isDark),
                  _buildProgressDot(2, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  OnboardingStepOne(
                    isDark: isDark,
                    onNext: _nextPage,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  OnboardingStepTwo(
                    isDark: isDark,
                    cycleLength: _cycleLength,
                    periodDuration: _periodDuration,
                    onCycleLengthChanged: (val) =>
                        setState(() => _cycleLength = val),
                    onPeriodDurationChanged: (val) =>
                        setState(() => _periodDuration = val),
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  OnboardingStepThree(
                    isDark: isDark,
                    cycleLength: _cycleLength,
                    periodDuration: _periodDuration,
                    selectedDate: _selectedDate,
                    onBack: _previousPage,
                    onComplete: () async {
                      if (_selectedDate != null) {
                        final settings = UserSettingsModel(
                          lastPeriodDate: _selectedDate!.toIso8601String(),
                          cycleLength: _cycleLength,
                          periodDuration: _periodDuration,
                        );
                        await DatabaseHelper.instance.create(settings);
                      }

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_completed', true);

                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index, bool isDark) {
    final isActive = _currentPage >= index;
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? OnboardingColors.primaryColor
              : (isDark ? Colors.grey[800] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
