import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:p_tracker/core/database/database_helper.dart';
import 'package:p_tracker/core/di/injection.dart';
import 'package:p_tracker/core/services/notification_service.dart';
import 'package:p_tracker/features/home/presentation/utils/home_constants.dart';
import 'package:p_tracker/features/onboarding/data/models/user_settings_model.dart';
import 'package:p_tracker/features/settings/presentation/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserSettingsModel? _settings;
  bool _isLoading = true;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.readSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _markPeriodStarted() async {
    if (_settings == null) return;

    final now = DateTime.now();
    final newSettings = UserSettingsModel(
      id: _settings!.id,
      lastPeriodDate: now.toIso8601String(),
      cycleLength: _settings!.cycleLength,
      periodDuration: _settings!.periodDuration,
      reminderEnabled: _settings!.reminderEnabled,
      reminderDaysBefore: _settings!.reminderDaysBefore,
      reminderTime: _settings!.reminderTime,
    );

    await DatabaseHelper.instance.create(newSettings);
    await _scheduleReminder(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period started! Cycle updated.')),
      );
      _loadSettings();
    }
  }

  Future<void> _scheduleReminder(UserSettingsModel settings) async {
    final notificationService = getIt<NotificationService>();
    await notificationService.cancelAllNotifications();

    if (settings.reminderEnabled) {
      final lastPeriodDate = DateTime.parse(settings.lastPeriodDate);
      final cycleLength = settings.cycleLength;
      final reminderDaysBefore = settings.reminderDaysBefore;

      await notificationService.schedulePeriodReminders(
        lastPeriodDate: lastPeriodDate,
        cycleLength: cycleLength,
        daysBefore: reminderDaysBefore,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? HomeColors.backgroundDark
            : HomeColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: HomeColors.primary),
        ),
      );
    }

    if (_settings == null) {
      return Scaffold(
        backgroundColor: isDark
            ? HomeColors.backgroundDark
            : HomeColors.backgroundLight,
        body: Center(
          child: Text(
            "No data found. Please restart onboarding.",
            style: GoogleFonts.nunitoSans(
              color: isDark ? HomeColors.textDark : HomeColors.textLight,
            ),
          ),
        ),
      );
    }

    // Calculations
    final lastPeriodRaw = DateTime.parse(_settings!.lastPeriodDate);
    // Normalize to start of day to avoid time-based diff errors
    final lastPeriod = DateTime(
      lastPeriodRaw.year,
      lastPeriodRaw.month,
      lastPeriodRaw.day,
    );
    final cycleLength = _settings!.cycleLength;
    final periodDuration = _settings!.periodDuration;

    // Calculate Next Period (Iterate to find the next one after today)
    DateTime nextPeriod = lastPeriod;
    final now = DateTime.now();
    // If last period is way in the past, project forward
    while (nextPeriod.isBefore(now) || nextPeriod.isAtSameMomentAs(now)) {
      // If the period *ended* before now, move to next.
      // Actually "Next Period" usually means the start of the next cycle.
      // If today is Jan 5, and last period started Jan 1. Next period is Jan 29.
      // If today is Jan 30, and last period started Jan 1. Next period was Jan 29 (in past).
      // We want the *upcoming* period start date.
      if (nextPeriod.add(Duration(days: cycleLength)).isAfter(now)) {
        nextPeriod = nextPeriod.add(Duration(days: cycleLength));
        break;
      }
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
    }

    // If the calculated next period is still the one corresponding to the *current* cycle
    // (e.g. we are in the middle of a cycle), we might want to show that.
    // But let's stick to "Next Period" meaning the start of the next cycle.

    // Calculate Ovulation and Fertile Window for the *current* cycle (relative to next period)
    // Ovulation is 14 days before the *next* period.
    final ovulationDate = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    final daysUntilPeriod = nextPeriod
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    final bgColor = isDark
        ? HomeColors.backgroundDark
        : HomeColors.backgroundLight;
    final surfaceColor = isDark
        ? HomeColors.surfaceDark
        : HomeColors.surfaceLight;
    final textColor = isDark ? HomeColors.textDark : HomeColors.textLight;
    final textMuted = isDark
        ? HomeColors.textMutedDark
        : HomeColors.textMutedLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Text(
                    "Home",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey[800] : Colors.transparent,
                    ),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                        if (result == true) {
                          _loadSettings();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Icon(Icons.settings, color: textMuted, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Today",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.water_drop,
                          iconColor: HomeColors.primary,
                          iconBg: isDark
                              ? HomeColors.primary.withOpacity(0.2)
                              : HomeColors.primarySoft,
                          title: "Next Period",
                          value: DateFormat('d MMM').format(nextPeriod),
                          subtitle: "$daysUntilPeriod days left",
                          subtitleColor: HomeColors.primary,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textMuted: textMuted,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.spa,
                          iconColor: HomeColors.secondary,
                          iconBg: isDark
                              ? HomeColors.secondary.withOpacity(0.2)
                              : HomeColors.secondarySoft,
                          title: "Fertile Window",
                          value:
                              "${DateFormat('d MMM').format(fertileStart)} - ${DateFormat('d MMM').format(fertileEnd)}",
                          subtitle:
                              "Ovulation: ${DateFormat('d MMM').format(ovulationDate)}",
                          subtitleColor: textMuted,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          textMuted: textMuted,
                          isDark: isDark,
                          isFertileCard: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Calendar
                  Container(
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
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _focusedMonth = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month - 1,
                                    );
                                  });
                                },
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: textMuted,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM y').format(_focusedMonth),
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _focusedMonth = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month + 1,
                                    );
                                  });
                                },
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Days Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        const SizedBox(height: 8),

                        // Calendar Grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildCalendarGrid(
                            isDark,
                            textColor,
                            lastPeriod,
                            cycleLength,
                            periodDuration,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Legend
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? surfaceColor.withOpacity(0.5)
                                : Colors.grey[50],
                            border: Border(
                              top: BorderSide(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[100]!,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem("Period", HomeColors.primary),
                              const SizedBox(width: 24),
                              _buildLegendItem("Fertile", HomeColors.secondary),
                              const SizedBox(width: 24),
                              _buildLegendItem(
                                "Ovulation",
                                HomeColors.accent,
                                icon: Icons.star,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cycle Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          "Cycle length:",
                          "$cycleLength days",
                          textMuted,
                          textColor,
                        ),
                        Container(
                          width: 1,
                          height: 16,
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                        ),
                        _buildStatItem(
                          "Period:",
                          "$periodDuration days",
                          textMuted,
                          textColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  ElevatedButton(
                    onPressed: _markPeriodStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: HomeColors.primary.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Mark Period Started",
                          style: GoogleFonts.nunitoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textMuted,
    required bool isDark,
    bool isFertileCard = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunitoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: subtitleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subtitle,
                style: GoogleFonts.nunitoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    bool isDark,
    Color textColor,
    DateTime lastPeriod,
    int cycleLength,
    int periodDuration,
  ) {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;
    // Sunday is 7, so if it's Sunday, offset is 0. If Monday (1), offset is 1.
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
          _focusedMonth.year,
          _focusedMonth.month,
          day,
        );

        // Calculate cycle day
        final diff = currentDate.difference(lastPeriod).inDays;
        final cycleDay = (diff % cycleLength + cycleLength) % cycleLength;

        // Determine status
        bool isPeriod = cycleDay < periodDuration;
        bool isOvulation = cycleDay == (cycleLength - 14);
        // Fertile window: 5 days before ovulation + ovulation day + 1 day after
        // Ovulation is at (cycleLength - 14)
        // Start: (cycleLength - 14) - 5 = cycleLength - 19
        // End: (cycleLength - 14) + 1 = cycleLength - 13
        bool isFertile =
            cycleDay >= (cycleLength - 19) && cycleDay <= (cycleLength - 13);

        // Rounded corners logic
        BorderRadius? borderRadius;
        if (isPeriod) {
          borderRadius = BorderRadius.circular(20);
        }
        if (isFertile) {
          // Check previous and next day for connectivity
          // This is a bit complex to do perfectly inside builder without pre-calculating all statuses.
          // For simplicity, let's just use rounded corners for start/end of the range within the month.

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

          // Also handle edge of week (Sunday/Saturday)
          if (index % 7 == 0) {
            // Sunday (start of row)
            borderRadius = BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topRight: isEnd ? Radius.circular(20) : Radius.zero,
              bottomRight: isEnd ? Radius.circular(20) : Radius.zero,
            );
          } else if (index % 7 == 6) {
            // Saturday (end of row)
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

  Widget _buildLegendItem(String label, Color color, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: color)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: HomeColors
                .textMutedLight, // Using light muted for legend usually
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: labelColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
