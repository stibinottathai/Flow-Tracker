import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p_tracker/features/home/presentation/utils/home_constants.dart';

class LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const LegendItem({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
            color: HomeColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
