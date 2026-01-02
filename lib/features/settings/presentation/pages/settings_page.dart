import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:p_tracker/core/database/database_helper.dart';
import 'package:p_tracker/core/di/injection.dart';
import 'package:p_tracker/core/services/notification_service.dart';
import 'package:p_tracker/core/theme/theme_provider.dart';
import 'package:p_tracker/features/home/presentation/utils/home_constants.dart';
import 'package:p_tracker/features/onboarding/data/models/user_settings_model.dart';
import 'package:p_tracker/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  UserSettingsModel? _settings;
  bool _isLoading = true;

  // Form state
  late DateTime _lastPeriodDate;
  late int _cycleLength;
  late int _periodDuration;

  // Reminder state
  bool _reminderEnabled = false;
  int _reminderDaysBefore = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.readSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        if (settings != null) {
          _lastPeriodDate = DateTime.parse(settings.lastPeriodDate);
          _cycleLength = settings.cycleLength;
          _periodDuration = settings.periodDuration;
          _reminderEnabled = settings.reminderEnabled;
          _reminderDaysBefore = settings.reminderDaysBefore;
        } else {
          // Fallback defaults if DB is empty for some reason
          _lastPeriodDate = DateTime.now();
          _cycleLength = 28;
          _periodDuration = 5;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final newSettings = UserSettingsModel(
      id: _settings!.id, // Keep same ID to update
      lastPeriodDate: _lastPeriodDate.toIso8601String(),
      cycleLength: _cycleLength,
      periodDuration: _periodDuration,
      reminderEnabled: _reminderEnabled,
      reminderDaysBefore: _reminderDaysBefore,
      reminderTime: "09:00", // Default time, ignored by new logic
    );

    await DatabaseHelper.instance.create(
      newSettings,
    ); // create uses insertOrReplace

    await _scheduleReminder();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate changes
    }
  }

  Future<void> _scheduleReminder() async {
    final notificationService = getIt<NotificationService>();
    await notificationService.cancelAllNotifications();

    if (_reminderEnabled) {
      await notificationService.requestPermissions();

      await notificationService.schedulePeriodReminders(
        lastPeriodDate: _lastPeriodDate,
        cycleLength: _cycleLength,
        daysBefore: _reminderDaysBefore,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HomeColors.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _lastPeriodDate) {
      setState(() {
        _lastPeriodDate = picked;
      });
    }
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Data"),
        content: const Text(
          "Are you sure you want to reset all data? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Reset"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear DB (assuming you have a method or just delete the file, but here we might just clear settings)
      // Since we don't have a clear method exposed easily, we can just delete the settings entry if we knew the ID,
      // or we can just clear shared prefs and let the user overwrite.
      // Better: Clear SharedPrefs flag and navigate to Onboarding.

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      // Also clear notifications
      await getIt<NotificationService>().cancelAllNotifications();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

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
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: HomeColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      child: Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Settings",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                children: [
                  // Cycle Details Section
                  _buildSectionHeader("CYCLE DETAILS", textMuted),
                  const SizedBox(height: 12),
                  Container(
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
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          title: "Last period started",
                          trailing: Row(
                            children: [
                              Text(
                                DateFormat('d MMM y').format(_lastPeriodDate),
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 14,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () => _selectDate(context),
                          isFirst: true,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                        _buildListTile(
                          title: "Cycle length",
                          trailing: _buildCounter(
                            value: _cycleLength,
                            onDecrement: () {
                              if (_cycleLength > 20)
                                setState(() => _cycleLength--);
                            },
                            onIncrement: () {
                              if (_cycleLength < 45)
                                setState(() => _cycleLength++);
                            },
                            isDark: isDark,
                            textColor: textColor,
                          ),
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                        _buildListTile(
                          title: "Period duration",
                          trailing: _buildCounter(
                            value: _periodDuration,
                            onDecrement: () {
                              if (_periodDuration > 1)
                                setState(() => _periodDuration--);
                            },
                            onIncrement: () {
                              if (_periodDuration < 10)
                                setState(() => _periodDuration++);
                            },
                            isDark: isDark,
                            textColor: textColor,
                          ),
                          isLast: true,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Period Reminder Section
                  _buildSectionHeader("PERIOD REMINDER", textMuted),
                  const SizedBox(height: 12),
                  Container(
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
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          title: "Enable Reminders",
                          leadingIcon: Icons.notifications_outlined,
                          leadingColor: const Color(0xFFEC4899),
                          leadingBg: const Color(0xFFEC4899).withOpacity(0.1),
                          trailing: Switch.adaptive(
                            value: _reminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _reminderEnabled = value;
                              });
                            },
                            activeColor: HomeColors.primary,
                          ),
                          isFirst: true,
                          isLast: !_reminderEnabled,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                        if (_reminderEnabled) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.05),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "You will receive 3 random reminders throughout the day.",
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 12,
                                      color: textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildListTile(
                            title: "Days before period",
                            trailing: _buildCounter(
                              value: _reminderDaysBefore,
                              onDecrement: () {
                                if (_reminderDaysBefore > 1)
                                  setState(() => _reminderDaysBefore--);
                              },
                              onIncrement: () {
                                if (_reminderDaysBefore < 7)
                                  setState(() => _reminderDaysBefore++);
                              },
                              isDark: isDark,
                              textColor: textColor,
                            ),
                            isLast: true,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: InkWell(
                              onTap: () async {
                                final notificationService =
                                    getIt<NotificationService>();
                                await notificationService.requestPermissions();
                                await notificationService.showInstantNotification(
                                  id: 999,
                                  title: 'Test Notification',
                                  body:
                                      'This is a test notification from P Tracker.',
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: HomeColors.primary.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: HomeColors.primary.withOpacity(0.05),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications_active_outlined,
                                      size: 18,
                                      color: HomeColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Send Test Notification",
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: HomeColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEC4899),
                          Color(0xFFF43F5E),
                        ], // Pink-500 to Rose-500
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF43F5E).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveSettings,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Text(
                            "Save Changes",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Theme Section
                  _buildSectionHeader("THEME", textMuted),
                  const SizedBox(height: 12),
                  Container(
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
                    ),
                    child: _buildListTile(
                      title: "Dark Mode",
                      trailing: Switch.adaptive(
                        value: isDark,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme(value);
                        },
                        activeColor: HomeColors.primary,
                      ),
                      isFirst: true,
                      isLast: true,
                      borderColor: borderColor,
                      textColor: textColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Backup & Reset Section
                  _buildSectionHeader("BACKUP & RESET", textMuted),
                  const SizedBox(height: 12),
                  Container(
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
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          title: "Backup Data",
                          leadingIcon: Icons.cloud_upload_outlined,
                          leadingColor: Colors.blue,
                          leadingBg: Colors.blue.withOpacity(0.1),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: textMuted,
                            size: 20,
                          ),
                          isFirst: true,
                          borderColor: borderColor,
                          textColor: textColor,
                          onTap: () {},
                        ),
                        _buildListTile(
                          title: "Reset Data",
                          leadingIcon: Icons.delete_outline,
                          leadingColor: Colors.red,
                          leadingBg: Colors.red.withOpacity(0.1),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: textMuted,
                            size: 20,
                          ),
                          isLast: true,
                          borderColor: borderColor,
                          textColor: textColor,
                          onTap: _resetData,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // About Section
                  _buildSectionHeader("ABOUT", textMuted),
                  const SizedBox(height: 12),
                  Container(
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
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          title: "App Version",
                          trailing: Text(
                            "1.0.0",
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              color: textMuted,
                            ),
                          ),
                          isFirst: true,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                        _buildListTile(
                          title: "Privacy Policy",
                          trailing: Icon(
                            Icons.open_in_new,
                            color: textMuted,
                            size: 20,
                          ),
                          isLast: true,
                          borderColor: borderColor,
                          textColor: textColor,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required Widget trailing,
    IconData? leadingIcon,
    Color? leadingColor,
    Color? leadingBg,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
    required Color borderColor,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: leadingBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(leadingIcon, color: leadingColor, size: 18),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter({
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounterBtn(Icons.remove, onDecrement, isDark),
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              "$value days",
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          _buildCounterBtn(Icons.add, onIncrement, isDark),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
      ),
    );
  }
}
