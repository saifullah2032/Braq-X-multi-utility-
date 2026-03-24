import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Minimalist footer for neo-brutalist dashboard
/// "BARQ X ENGINE • PHASE 9 COMPLETE" text, centered
class DashboardFooter extends StatelessWidget {
  final String text;

  const DashboardFooter({
    super.key,
    this.text = 'BARQ X ENGINE • PHASE 9 COMPLETE',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
