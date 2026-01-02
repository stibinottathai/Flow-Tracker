import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p_tracker/features/onboarding/presentation/utils/onboarding_constants.dart';
import 'package:p_tracker/features/onboarding/presentation/widgets/onboarding_step_one.dart';
import 'package:p_tracker/features/onboarding/presentation/widgets/onboarding_step_two.dart';
import 'package:p_tracker/features/onboarding/presentation/widgets/onboarding_step_three.dart';
import 'package:p_tracker/features/home/presentation/pages/home_page.dart';
import 'package:p_tracker/core/database/database_helper.dart';
import 'package:p_tracker/features/onboarding/data/models/user_settings_model.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isDark = false; // Local state for demo, ideally use ThemeProvider

  int _cycleLength = 28;
  int _periodDuration = 5;
  DateTime? _selectedDate;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
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
    final bgColor = _isDark
        ? OnboardingColors.bgDark
        : OnboardingColors.bgLight;
    final textMain = _isDark
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
                    onPressed: _toggleTheme,
                    icon: Icon(
                      _isDark
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
                  _buildProgressDot(0),
                  _buildProgressDot(1),
                  _buildProgressDot(2),
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
                    isDark: _isDark,
                    onNext: _nextPage,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  OnboardingStepTwo(
                    isDark: _isDark,
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
                    isDark: _isDark,
                    cycleLength: _cycleLength,
                    periodDuration: _periodDuration,
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

  Widget _buildProgressDot(int index) {
    final isActive = _currentPage >= index;
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? OnboardingColors.primaryColor
              : (_isDark ? Colors.grey[800] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
