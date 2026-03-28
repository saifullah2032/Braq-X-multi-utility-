import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Premium Floating Action Button for neo-brutalist dashboard
/// Square design with gear icon, lavender background, hard shadow
class PremiumFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final IconData icon;

  const PremiumFAB({
    super.key,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFBCB1DE),
    this.iconColor = AppColors.textPrimary,
    this.size = 56.0,
    this.icon = Icons.settings,
  });

  @override
  State<PremiumFAB> createState() => _PremiumFABState();
}

class _PremiumFABState extends State<PremiumFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 4 : 0,
          _isPressed ? 4 : 0,
          0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Hard shadow
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: AppColors.shadowColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Main FAB button
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 3.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
