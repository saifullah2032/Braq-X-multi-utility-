import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';

/// Reusable neo-brutalist card component
/// Forms the foundation of all UI containers
class NeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final double cornerRadius;
  final double shadowOffset;
  final VoidCallback? onTap;
  final bool isSelected;

  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConfig.innerPadding),
    this.borderWidth = AppConfig.cardBorderWidth,
    this.borderColor = AppColors.textPrimary,
    this.backgroundColor = Colors.white,
    this.cornerRadius = AppConfig.cornerRadiusSlight,
    this.shadowOffset = AppConfig.shadowOffset,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: isSelected ? AppColors.accentPrimary : borderColor,
          width: isSelected ? borderWidth + 1 : borderWidth,
        ),
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: child,
    );

    final withShadow = Stack(
      children: [
        // Shadow layer
        Positioned(
          top: shadowOffset,
          left: shadowOffset,
          right: -shadowOffset,
          bottom: -shadowOffset,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(cornerRadius),
            ),
          ),
        ),
        // Card on top
        card,
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: withShadow,
      );
    }

    return withShadow;
  }
}

/// Small compact card for minimal content
class NeoCardSmall extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;

  const NeoCardSmall({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(8.0),
      borderWidth: AppConfig.secondaryBorderWidth,
      backgroundColor: Colors.white,
      cornerRadius: AppConfig.cornerRadiusSharp,
      shadowOffset: 4.0,
      onTap: onTap,
      isSelected: isSelected,
      child: child,
    );
  }
}
