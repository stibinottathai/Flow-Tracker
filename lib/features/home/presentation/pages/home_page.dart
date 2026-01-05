import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:p_tracker/core/database/database_helper.dart';
import 'package:p_tracker/core/di/injection.dart';
import 'package:p_tracker/core/services/notification_service.dart';
import 'package:p_tracker/features/home/presentation/utils/home_constants.dart';
import 'package:p_tracker/features/onboarding/data/models/user_settings_model.dart';
import 'package:p_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:p_tracker/features/home/presentation/pages/widgets/status_card.dart';
import 'package:p_tracker/features/home/presentation/pages/widgets/calendar_widget.dart';
import 'package:p_tracker/features/home/presentation/pages/widgets/stat_item.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? HomeColors.surfaceDark
        : HomeColors.surfaceLight;
    final textColor = isDark ? HomeColors.textDark : HomeColors.textLight;
    final textMuted = isDark
        ? HomeColors.textMutedDark
        : HomeColors.textMutedLight;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Mark Period Started?",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          "This will start a new cycle from today. Are you sure?",
          style: GoogleFonts.nunitoSans(fontSize: 16, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "No",
              style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.bold,
                color: textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Yes",
              style: GoogleFonts.nunitoSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // const SizedBox(width: 32),
                  Text(
                    "Welcome!",
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: StatusCard(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatusCard(
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

                    const SizedBox(height: 16),

                    // Calendar
                    CalendarWidget(
                      focusedMonth: _focusedMonth,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      textMuted: textMuted,
                      lastPeriod: lastPeriod,
                      cycleLength: cycleLength,
                      periodDuration: periodDuration,
                      onPreviousMonth: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                          );
                        });
                      },
                      onNextMonth: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                          );
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Cycle Stats
                    Container(
                      padding: const EdgeInsets.all(12),
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
                          StatItem(
                            label: "Cycle length:",
                            value: "$cycleLength days",
                            labelColor: textMuted,
                            valueColor: textColor,
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                          ),
                          StatItem(
                            label: "Period:",
                            value: "$periodDuration days",
                            labelColor: textMuted,
                            valueColor: textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Action Button - Fixed at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: ElevatedButton(
                onPressed: _markPeriodStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
            ),
          ],
        ),
      ),
    );
  }
}
