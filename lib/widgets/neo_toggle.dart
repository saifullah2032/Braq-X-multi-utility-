import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';

/// Neo-brutalist toggle button
/// Simple on/off stamp button with frozen architecture
class NeoToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const NeoToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.size = AppConfig.toggleStampSize,
    this.activeColor = AppColors.accentPrimary,
    this.inactiveColor = AppColors.accentTertiary,
  });

  @override
  State<NeoToggle> createState() => _NeoToggleState();
}

class _NeoToggleState extends State<NeoToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConfig.toggleTransitionDuration,
      vsync: this,
    );
    if (widget.value) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NeoToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            widget.onChanged(!widget.value);
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final Color color = Color.lerp(
                widget.inactiveColor,
                widget.activeColor,
                _animationController.value,
              )!;

              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: AppColors.textPrimary,
                    width: AppConfig.cardBorderWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConfig.cornerRadiusSlight,
                  ),
                ),
                child: Center(
                  child: _animationController.value > 0.5
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: widget.size * 0.6,
                        )
                      : SizedBox.shrink(),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Master toggle for arming/disarming all gestures
class MasterToggle extends StatelessWidget {
  final bool isArmed;
  final VoidCallback onToggle;

  const MasterToggle({
    super.key,
    required this.isArmed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: AppConfig.masterToggleHeight,
        padding: EdgeInsets.symmetric(
          horizontal: AppConfig.masterTogglePadding,
        ),
        decoration: BoxDecoration(
          color: isArmed ? AppColors.accentPrimary : AppColors.accentQuaternary,
          border: Border.all(
            color: AppColors.textPrimary,
            width: AppConfig.cardBorderWidth,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArmed ? 'BARQ X ARMED' : 'BARQ X DISARMED',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AnimatedRotation(
              turns: isArmed ? 0.5 : 0.0,
              duration: AppConfig.toggleTransitionDuration,
              child: Icon(
                Icons.power_settings_new,
                color: Colors.white,
                size: 24.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
