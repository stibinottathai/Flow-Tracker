import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:p_tracker/features/onboarding/presentation/utils/onboarding_constants.dart';

class OnboardingStepOne extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNext;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const OnboardingStepOne({
    super.key,
    required this.isDark,
    required this.onNext,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark
        ? OnboardingColors.surfaceDark
        : OnboardingColors.surfaceLight;
    final textMain = isDark
        ? OnboardingColors.textMainDark
        : OnboardingColors.textMainLight;
    final textSub = isDark
        ? OnboardingColors.textSubDark
        : OnboardingColors.textSubLight;
    final borderColor = isDark
        ? OnboardingColors.borderDark
        : OnboardingColors.borderLight;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Background (Simulated with Container)
          Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? OnboardingColors.primaryColor.withOpacity(0.1)
                      : OnboardingColors.primarySoft,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header
                Text(
                  "Track Your Cycle",
                  style: GoogleFonts.nunitoSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: OnboardingColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Simple & private period tracker",
                  style: GoogleFonts.nunitoSans(fontSize: 14, color: textSub),
                ),
                const SizedBox(height: 32),

                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "When did your last period start?",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Knowing this helps us predict your next cycle and fertile window accurately.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          color: textSub,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Date Picker Button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ElevatedButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: isDark
                                            ? ThemeData.dark().copyWith(
                                                colorScheme: ColorScheme.dark(
                                                  primary: OnboardingColors
                                                      .primaryColor,
                                                  onPrimary: Colors.white,
                                                  surface: OnboardingColors
                                                      .surfaceDark,
                                                  onSurface: OnboardingColors
                                                      .textMainDark,
                                                ),
                                              )
                                            : ThemeData.light().copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: OnboardingColors
                                                      .primaryColor,
                                                  onPrimary: Colors.white,
                                                  surface: OnboardingColors
                                                      .surfaceLight,
                                                  onSurface: OnboardingColors
                                                      .textMainLight,
                                                ),
                                              ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    onDateSelected(date);
                                    onNext();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      OnboardingColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  overlayColor: OnboardingColors.primaryHover,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  shadowColor: OnboardingColors.primaryColor
                                      .withOpacity(0.3),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Select Date",
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(target: 1)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(0.98, 0.98),
                                duration: 100.ms,
                                curve: Curves.easeInOut,
                              ),

                          // Decorative dots
                          Positioned(
                            top: -8,
                            right: -8,
                            child:
                                Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.yellow,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1.2, 1.2),
                                      duration: 1000.ms,
                                    ),
                          ),
                          Positioned(
                            bottom: -4,
                            left: -4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          selectedDate != null
                              ? DateFormat('d MMM y').format(selectedDate!)
                              : "Example: 12 Jan 2026",
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSub,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // SVG Graphic
                      Opacity(
                        opacity: isDark ? 0.6 : 0.8,
                        child: SvgPicture.string('''
<svg viewBox="0 0 200 120" width="180" height="120" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="paint0_linear" x1="100" y1="30" x2="100" y2="190" gradientUnits="userSpaceOnUse">
<stop stop-color="#F43F6E"/>
<stop offset="1" stop-color="#F43F6E" stop-opacity="0"/>
</linearGradient>
<linearGradient id="paint1_linear" x1="100" y1="50" x2="100" y2="170" gradientUnits="userSpaceOnUse">
<stop stop-color="#F43F6E"/>
<stop offset="1" stop-color="#F43F6E" stop-opacity="0"/>
</linearGradient>
</defs>
<circle cx="100" cy="110" r="80" fill="url(#paint0_linear)" fill-opacity="0.1"/>
<circle cx="100" cy="110" r="60" fill="url(#paint1_linear)" fill-opacity="0.1"/>
<path d="M70 60C70 43.4315 83.4315 30 100 30C116.569 30 130 43.4315 130 60C130 76.5685 116.569 90 100 90C83.4315 90 70 76.5685 70 60Z" fill="#F43F6E" fill-opacity="0.1"/>
<path d="M92 45L100 35L108 45" stroke="#F43F6E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
                          ''', height: 120),
                      ),

                      const SizedBox(height: 32),

                      // Next Button
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: ElevatedButton(
                      //     onPressed: onNext,
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: OnboardingColors.primaryColor,
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.symmetric(vertical: 16),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(16),
                      //       ),
                      //       elevation: 4,
                      //       shadowColor: OnboardingColors.primaryColor
                      //           .withOpacity(0.3),
                      //     ),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Text(
                      //           "Next",
                      //           style: GoogleFonts.nunitoSans(
                      //             fontWeight: FontWeight.w600,
                      //             fontSize: 16,
                      //           ),
                      //         ),
                      //         const SizedBox(width: 8),
                      //         const Icon(Icons.arrow_forward_rounded, size: 20),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
