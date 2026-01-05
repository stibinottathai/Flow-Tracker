import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:p_tracker/features/home/presentation/utils/home_constants.dart';
import 'package:p_tracker/features/home/presentation/pages/widgets/legend_item.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final Color textMuted;
  final DateTime lastPeriod;
  final int cycleLength;
  final int periodDuration;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarWidget({
    super.key,
    required this.focusedMonth,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.textMuted,
    required this.lastPeriod,
    required this.cycleLength,
    required this.periodDuration,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: Column(
        children: [
          // Calendar Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPreviousMonth,
                  icon: Icon(Icons.chevron_left, color: textMuted),
                ),
                Text(
                  DateFormat('MMMM y').format(focusedMonth),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: Icon(Icons.chevron_right, color: textMuted),
                ),
              ],
            ),
          ),

          // Days Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["S", "M", "T", "W", "T", "F", "S"]
                  .map(
                    (day) => SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Calendar Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildCalendarGrid(),
          ),

          const SizedBox(height: 8),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? surfaceColor.withOpacity(0.5) : Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                LegendItem(label: "Period", color: HomeColors.primary),
                SizedBox(width: 16),
                LegendItem(label: "Fertile", color: HomeColors.secondary),
                SizedBox(width: 16),
                LegendItem(
                  label: "Ovulation",
                  color: HomeColors.accent,
                  icon: Icons.star,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final firstDayWeekday = DateTime(
      focusedMonth.year,
      focusedMonth.month,
      1,
    ).weekday;
    final emptyStart = firstDayWeekday % 7;
    final days = List.generate(daysInMonth, (index) => index + 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: emptyStart + days.length,
      itemBuilder: (context, index) {
        if (index < emptyStart) return const SizedBox();

        final day = days[index - emptyStart];
        final currentDate = DateTime(
          focusedMonth.year,
          focusedMonth.month,
          day,
        );

        // Calculate cycle day
        final diff = currentDate.difference(lastPeriod).inDays;
        final cycleDay = (diff % cycleLength + cycleLength) % cycleLength;

        // Determine status
        bool isPeriod = cycleDay < periodDuration;
        bool isOvulation = cycleDay == (cycleLength - 14);
        bool isFertile =
            cycleDay >= (cycleLength - 19) && cycleDay <= (cycleLength - 13);

        // Rounded corners logic
        BorderRadius? borderRadius;
        if (isPeriod) {
          borderRadius = BorderRadius.circular(20);
        }
        if (isFertile) {
          bool isStart = cycleDay == (cycleLength - 19);
          bool isEnd = cycleDay == (cycleLength - 13);

          if (isStart) {
            borderRadius = const BorderRadius.horizontal(
              left: Radius.circular(20),
            );
          } else if (isEnd) {
            borderRadius = const BorderRadius.horizontal(
              right: Radius.circular(20),
            );
          } else {
            borderRadius = BorderRadius.zero;
          }

          // Handle edge of week (Sunday/Saturday)
          if (index % 7 == 0) {
            borderRadius = BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topRight: isEnd ? Radius.circular(20) : Radius.zero,
              bottomRight: isEnd ? Radius.circular(20) : Radius.zero,
            );
          } else if (index % 7 == 6) {
            borderRadius = BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topLeft: isStart ? Radius.circular(20) : Radius.zero,
              bottomLeft: isStart ? Radius.circular(20) : Radius.zero,
            );
          }
        }

        Color? bgColor;
        Color? fgColor;

        if (isPeriod) {
          bgColor = isDark
              ? HomeColors.primary.withOpacity(0.2)
              : HomeColors.primarySoft;
          fgColor = isDark ? const Color(0xFFFDA4AF) : HomeColors.primary;
        } else if (isFertile) {
          bgColor = isDark
              ? HomeColors.secondary.withOpacity(0.2)
              : HomeColors.secondarySoft;
          fgColor = isDark ? const Color(0xFF86EFAC) : HomeColors.secondary;
        } else {
          fgColor = textColor;
        }

        return Container(
          decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                "$day",
                style: GoogleFonts.nunitoSans(
                  fontWeight: (isPeriod || isFertile)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: fgColor,
                ),
              ),
              if (isOvulation)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: isDark ? Colors.yellow[400] : HomeColors.accent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
