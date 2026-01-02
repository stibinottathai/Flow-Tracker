import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:p_tracker/features/onboarding/presentation/utils/onboarding_constants.dart';

class OnboardingStepThree extends StatelessWidget {
  final bool isDark;
  final int cycleLength;
  final int periodDuration;
  final DateTime? selectedDate;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const OnboardingStepThree({
    super.key,
    required this.isDark,
    required this.cycleLength,
    required this.periodDuration,
    required this.selectedDate,
    required this.onBack,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? OnboardingColors.textMainDark
        : OnboardingColors.textMainLight;
    final textSub = isDark
        ? OnboardingColors.textSubDark
        : OnboardingColors.textSubLight;
    final surfaceColor = isDark
        ? OnboardingColors.surfaceDark
        : OnboardingColors.surfaceLight;
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
                color: surfaceColor,
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
                  // Background Blobs (Animated)
                  Positioned(
                    top: -40,
                    right: -40,
                    child:
                        Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.pink[200]!.withOpacity(
                                  isDark ? 0.1 : 0.3,
                                ),
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 7.seconds,
                            )
                            .blur(
                              begin: const Offset(60, 60),
                              end: const Offset(60, 60),
                            ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -40,
                    child:
                        Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.purple[200]!.withOpacity(
                                  isDark ? 0.1 : 0.3,
                                ),
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 7.seconds,
                              delay: 2.seconds,
                            )
                            .blur(
                              begin: const Offset(60, 60),
                              end: const Offset(60, 60),
                            ),
                  ),

                  Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 40,
                          left: 24,
                          right: 24,
                          bottom: 16,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Almost Done",
                              style: GoogleFonts.nunito(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your cycle summary",
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textSub,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: 96,
                              height: 1,
                              decoration: BoxDecoration(
                                color: borderColor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Summary Items
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildSummaryItem(
                              icon: Icons.calendar_today_rounded,
                              label: "Last period started",
                              value: selectedDate != null
                                  ? DateFormat('d MMM y').format(selectedDate!)
                                  : "Not selected",
                              color: OnboardingColors.primaryColor,
                              bgColor: isDark
                                  ? OnboardingColors.primaryColor.withOpacity(
                                      0.1,
                                    )
                                  : const Color(0xFFFFF1F2), // Rose-50
                              borderColor: borderColor,
                              textMain: textMain,
                              textSub: textSub,
                              surfaceColor: isDark
                                  ? Colors.grey[800]!.withOpacity(0.5)
                                  : Colors.white,
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryItem(
                              icon: Icons.donut_large_rounded,
                              label: "Cycle Length",
                              value: "$cycleLength days",
                              color: Colors.green,
                              bgColor: isDark
                                  ? Colors.green.withOpacity(0.1)
                                  : const Color(0xFFF0FDF4), // Green-50
                              borderColor: borderColor,
                              textMain: textMain,
                              textSub: textSub,
                              surfaceColor: isDark
                                  ? Colors.grey[800]!.withOpacity(0.5)
                                  : Colors.white,
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryItem(
                              icon: Icons.water_drop_rounded,
                              label: "Period Duration",
                              value: "$periodDuration days",
                              color: OnboardingColors.primaryColor,
                              bgColor: isDark
                                  ? OnboardingColors.primaryColor.withOpacity(
                                      0.1,
                                    )
                                  : const Color(0xFFFFF1F2), // Rose-50
                              borderColor: borderColor,
                              textMain: textMain,
                              textSub: textSub,
                              surfaceColor: isDark
                                  ? Colors.grey[800]!.withOpacity(0.5)
                                  : Colors.white,
                            ),

                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: onBack,
                              icon: Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: textSub,
                              ),
                              label: Text(
                                "Edit Details",
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textSub,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: borderColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Footer
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: borderColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: onComplete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: OnboardingColors.primaryColor,
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
                                    "Start Tracking",
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Your data is encrypted and private.",
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: textSub.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required Color textMain,
    required Color textSub,
    required Color surfaceColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textSub,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: color.withOpacity(0.0),
            size: 24,
          ).animate(target: 1).fadeIn(),
        ],
      ),
    );
  }
}
