import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p_tracker/features/onboarding/presentation/utils/onboarding_constants.dart';

class OnboardingStepTwo extends StatelessWidget {
  final bool isDark;
  final int cycleLength;
  final int periodDuration;
  final ValueChanged<int> onCycleLengthChanged;
  final ValueChanged<int> onPeriodDurationChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingStepTwo({
    super.key,
    required this.isDark,
    required this.cycleLength,
    required this.periodDuration,
    required this.onCycleLengthChanged,
    required this.onPeriodDurationChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? OnboardingColors.textMainDark
        : OnboardingColors.textMainLight;
    final textSub = isDark
        ? OnboardingColors.textSubDark
        : OnboardingColors.textSubLight;
    final inputBg = isDark
        ? OnboardingColors.inputBgDark
        : OnboardingColors.inputBgLight;
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final borderColor = isDark
        ? OnboardingColors.borderDark
        : OnboardingColors.borderLight;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Card Container
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 600),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Blobs
                  Positioned(
                    top: -80,
                    right: -80,
                    child:
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: OnboardingColors.primaryColor.withOpacity(
                              0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ).animate().blur(
                          begin: const Offset(60, 60),
                          end: const Offset(60, 60),
                        ),
                  ),
                  Positioned(
                    top: 80,
                    left: -80,
                    child:
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ).animate().blur(
                          begin: const Offset(60, 60),
                          end: const Offset(60, 60),
                        ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 24,
                              height: 8,
                              decoration: BoxDecoration(
                                color: OnboardingColors.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Cycle Details",
                          style: GoogleFonts.nunitoSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 64,
                          height: 4,
                          decoration: BoxDecoration(
                            color: OnboardingColors.primaryColor.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Cycle Length Input
                        _buildCounterInput(
                          label: "Average cycle length",
                          value: cycleLength,
                          onDecrement: () {
                            if (cycleLength > 1) {
                              onCycleLengthChanged(cycleLength - 1);
                            }
                          },
                          onIncrement: () {
                            onCycleLengthChanged(cycleLength + 1);
                          },
                          textMain: textMain,
                          textSub: textSub,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 24),

                        // Period Duration Input
                        _buildCounterInput(
                          label: "Period duration",
                          value: periodDuration,
                          onDecrement: () {
                            if (periodDuration > 1) {
                              onPeriodDurationChanged(periodDuration - 1);
                            }
                          },
                          onIncrement: () {
                            onPeriodDurationChanged(periodDuration + 1);
                          },
                          textMain: textMain,
                          textSub: textSub,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 24),
                        Text(
                          "These values help predict your next period and fertile days accurately.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 14,
                            color: textSub,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Navigation Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onBack,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textMain,
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.grey[600]!
                                        : Colors.grey[200]!,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Back",
                                      style: GoogleFonts.nunitoSans(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      OnboardingColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: OnboardingColors.primaryColor
                                      .withOpacity(0.3),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Next",
                                      style: GoogleFonts.nunitoSans(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterInput({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color textMain,
    required Color textSub,
    required Color inputBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
            children: [
              TextSpan(
                text: " (days)",
                style: GoogleFonts.nunitoSans(
                  fontWeight: FontWeight.normal,
                  color: textSub,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              _buildCounterButton(
                icon: Icons.remove_rounded,
                onPressed: onDecrement,
                isDark: isDark,
                textSub: textSub,
              ),
              Expanded(
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
              ),
              _buildCounterButton(
                icon: Icons.add_rounded,
                onPressed: onIncrement,
                isDark: isDark,
                textMain: textMain,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    Color? textSub,
    Color? textMain,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: isDark ? const Color(0xFF3F3F46) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Icon(icon, color: textMain ?? textSub, size: 24),
        ),
      ),
    );
  }
}
