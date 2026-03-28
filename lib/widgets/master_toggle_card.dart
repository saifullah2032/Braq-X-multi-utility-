import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhanced Master Toggle Card for premium dashboard
/// Wide flat card with status text and chunky 2D toggle switch
/// Shows "Icy Blue" glow (#B4D7F1) when service is running with pulse animation
class MasterToggleCard extends StatefulWidget {
  final bool isArmed;
  final bool isServiceRunning;
  final VoidCallback onToggle;

  const MasterToggleCard({
    super.key,
    required this.isArmed,
    this.isServiceRunning = false,
    required this.onToggle,
  });

  @override
  State<MasterToggleCard> createState() => _MasterToggleCardState();
}

class _MasterToggleCardState extends State<MasterToggleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation if service is already running
    if (widget.isServiceRunning) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(MasterToggleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start/stop pulse animation based on service state
    if (widget.isServiceRunning && !oldWidget.isServiceRunning) {
      _pulseController.repeat();
    } else if (!widget.isServiceRunning && oldWidget.isServiceRunning) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Icy Blue glow color for active service
    const icyBlueGlow = Color(0xFFB4D7F1);
    
    return GestureDetector(
      onTap: widget.onToggle,
      child: Stack(
        children: [
          // Pulse effect (animated glow when service running)
          if (widget.isServiceRunning)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Positioned(
                  left: -8 - (_pulseAnimation.value * 6),
                  top: -8 - (_pulseAnimation.value * 6),
                  right: -8 - (_pulseAnimation.value * 6),
                  bottom: -8 - (_pulseAnimation.value * 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: icyBlueGlow.withOpacity(0.2 * (1 - _pulseAnimation.value)),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: icyBlueGlow.withOpacity(0.3 * (1 - _pulseAnimation.value)),
                          blurRadius: 16 + (_pulseAnimation.value * 8),
                          spreadRadius: 2 + (_pulseAnimation.value * 4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Service active glow (behind card)
          if (widget.isServiceRunning)
            Positioned(
              left: -4,
              top: -4,
              right: -4,
              bottom: -4,
              child: Container(
                decoration: BoxDecoration(
                  color: icyBlueGlow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: icyBlueGlow.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // Hard shadow (8px offset)
          Positioned(
            left: 8,
            top: 8,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shadowColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Main card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: widget.isArmed ? AppColors.masterToggleActive : AppColors.background,
              border: Border.all(
                color: widget.isServiceRunning 
                  ? icyBlueGlow 
                  : AppColors.borderPrimary,
                width: widget.isServiceRunning ? 4.0 : 3.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Title and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BARQ X',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: widget.isArmed ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isServiceRunning 
                          ? 'SYSTEM STATUS: ARMED • GESTURES ACTIVE'
                          : 'SYSTEM STATUS: ${widget.isArmed ? 'ARMING...' : 'DISARMED'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isServiceRunning 
                            ? icyBlueGlow 
                            : (widget.isArmed ? Colors.white.withOpacity(0.9) : AppColors.textSecondary),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Chunky 2D toggle switch
                Container(
                  width: 80,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.isArmed ? Colors.white : AppColors.disabledColor,
                    border: Border.all(
                      color: widget.isServiceRunning 
                        ? icyBlueGlow 
                        : AppColors.borderPrimary,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // Background toggle track
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Animated toggle thumb
                      AnimatedAlign(
                        alignment: widget.isArmed ? Alignment.centerRight : Alignment.centerLeft,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: widget.isArmed 
                              ? (widget.isServiceRunning ? icyBlueGlow : AppColors.masterToggleActive)
                              : AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: widget.isServiceRunning 
                                ? icyBlueGlow 
                                : AppColors.borderPrimary,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.isArmed ? '✓' : '○',
                              style: TextStyle(
                                color: widget.isServiceRunning ? Colors.black87 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
