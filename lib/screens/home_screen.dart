import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../constants/app_colors.dart';
import '../providers/armed_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/service_running_provider.dart';
import '../services/gesture_integration_service.dart';
import '../services/foreground_service_manager.dart';
import '../services/disarm_broadcast_service.dart';
import '../widgets/neo_brutalist_background.dart';
import '../widgets/sticker_badge.dart';

/// Sticker shape enum for the Recent Triggers collection
enum StickerShape { square, circle, star }

/// Star shape painter for the sticker collection
class StarShapePainter extends CustomPainter {
  final Color color;

  StarShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final shadowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5; // Leave space for border

    // Draw shadow first
    final shadowPath = _createStarPath(center + const Offset(4, 4), radius);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw filled star
    final starPath = _createStarPath(center, radius);
    canvas.drawPath(starPath, paint);
    canvas.drawPath(starPath, borderPaint);
  }

  Path _createStarPath(Offset center, double radius) {
    final path = Path();
    const double angle = math.pi / 5; // 36 degrees in radians
    
    // Create 5-point star
    for (int i = 0; i < 10; i++) {
      final double currentRadius = i.isEven ? radius : radius * 0.4;
      final double x = center.dx + currentRadius * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + currentRadius * math.sin(i * angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium Single-Page Gesture-Utility Dashboard
/// 100% Fidelity Neo-Brutalism + 2D Comic/Sticker aesthetic
/// NO bottom navbar - FAB for settings access
/// ALL corners: 0px radius (sharp edges)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DisarmBroadcastService _disarmBroadcastService;

  @override
  void initState() {
    super.initState();
    developer.log('HomeScreen mounted', name: 'HomeScreen');

    // Initialize disarm broadcast receiver
    _disarmBroadcastService = DisarmBroadcastService();
    _disarmBroadcastService.startListening(() {
      developer.log(
        'Disarm broadcast received, disarming app',
        name: 'HomeScreen',
      );
      ref.read(armedProvider.notifier).disarmFromNotification();
      ref.read(serviceRunningProvider.notifier).setServiceRunning(false);
    });

    // Initialize gesture integration on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log(
        'Starting gesture integration service initialization...',
        name: 'HomeScreen',
      );
      try {
        ref
            .read(gestureIntegrationProvider)
            .initialize()
            .then((_) {
              developer.log(
                '✓ Gesture integration service initialized successfully',
                name: 'HomeScreen',
              );
            })
            .catchError((e, st) {
              developer.log(
                '✗ Error initializing gesture service: $e',
                name: 'HomeScreen',
                error: e,
                stackTrace: st,
              );
            });
      } catch (e, st) {
        developer.log(
          '✗ Exception initializing gesture service: $e',
          name: 'HomeScreen',
          error: e,
          stackTrace: st,
        );
      }
    });
  }

  @override
  void dispose() {
    ref.read(gestureIntegrationProvider).dispose();
    super.dispose();
  }

  // ============================================================
  // BRUTALIST DECORATION HELPER
  // 0px radius, 3.5px black border, 8px hard offset shadow
  // ============================================================
  BoxDecoration _brutalistDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.zero, // 0px radius - sharp edges
      border: Border.all(color: Colors.black, width: 3.5),
      boxShadow: const [
        BoxShadow(
          color: Colors.black,
          offset: Offset(8, 8), // 8px hard shadow
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArmed = ref.watch(armedProvider);
    final settings = ref.watch(settingsProvider);
    final isServiceRunning = ref.watch(serviceRunningProvider);

    return NeoBrutalistBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildPremiumFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(), // Lock dashboard - no scrolling
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20), // More aggressive side margins
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Tactical panel distribution
              children: [
                // ========================================
                // 1. HEADER SECTION
                // ========================================
                _buildHeader(),
                const SizedBox(height: 32), // More spacious after header

                // ========================================
                // 2. CARD 1: MAIN STATUS & ARMING (Blue)
                // ========================================
                _buildStatusCard(
                  context,
                  ref,
                  isArmed: isArmed,
                  isServiceRunning: isServiceRunning,
                ),
                const SizedBox(height: 20), // Consistent card spacing

                // ========================================
                // 3. CARD 2: GESTURE PALETTE (Peach)
                // ========================================
                _buildProtocolPaletteCard(settings),
                const SizedBox(height: 20), // Consistent card spacing

                // ========================================
                // 4. CARD 3: VERIFICATION CHECKLIST (Lavender)
                // ========================================
                _buildVerificationCard(settings),
                const SizedBox(height: 28), // More space before final section

                // ========================================
                // 5. RECENT TRIGGERS SECTION
                // ========================================
                _buildRecentTriggersSection(),
                
                const SizedBox(height: 100), // More space for FAB and scroll area
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. HEADER & TITLE - Professional Neo-Brutalist Hierarchy
  // Optimized spacing and proportions for aggressive design
  // ============================================================
  Widget _buildHeader() {
    return Row(
      children: [
        // Title: "BARQ X CONTROL\nCENTER" with enhanced typography
        const Text(
          'BARQ X CONTROL\nCENTER',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 38, // Slightly larger for more presence
            fontWeight: FontWeight.bold,
            height: 0.85, // Tighter line height for aggressive stacking
            letterSpacing: 2.5, // More aggressive letter spacing
            color: AppColors.textPrimary,
          ),
        ),
        // Star Icon: Enhanced Peach container with precise spacing
        Container(
          padding: const EdgeInsets.all(12), // More generous padding
          decoration: _brutalistDecoration(const Color(0xFFFFCCB6)), // Peach
          child: const Icon(
            Icons.star_rounded,
            size: 28, // Slightly larger for better balance
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 2. CARD 1: MAIN STATUS & ARMING (Tactical Dashboard)
  // Sky Blue (#B4D7F1), enhanced tactical spacing and hierarchy
  // ============================================================
  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref, {
    required bool isArmed,
    required bool isServiceRunning,
  }) {
    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFB4D7F1)), // Sky Blue
      child: Stack(
        children: [
          // Large bolt icon (tactical background element)
          const Positioned(
            right: 15,
            top: 15,
            child: Icon(
              Icons.bolt,
              size: 85, // Slightly larger for more presence
              color: Colors.white60, // More subtle opacity for tactical feel
            ),
          ),
          // Sticker Badge (overlapping corner)
          const Positioned(
            right: -6,
            top: -6,
            child: StickerBadge(),
          ),
          // Main tactical content with precise spacing
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24), // Asymmetric padding for tactical hierarchy
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "ACTIVE ENGINE:" tactical label
                const Text(
                  'ACTIVE ENGINE:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900, // Heavier weight for tactical feel
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6), // Tight spacing for hierarchy
                // "BARQ X GESTURE SYSTEM" main title
                const Text(
                  'BARQ X GESTURE SYSTEM',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 32, // Slightly larger for more impact
                    letterSpacing: 1.5,
                    height: 0.9,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8), // Controlled spacing
                // Status description with tactical formatting
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1), // Subtle background for tactical readout
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    isArmed
                        ? 'MASTERED KINETIC INTEGRATION'
                        : 'SYSTEM STANDBY - DISARMED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20), // More generous space before action
                // Master Toggle Button (tactical command button)
                GestureDetector(
                  onTap: () async {
                    await ref.read(armedProvider.notifier).toggle();
                    final newArmedState = ref.read(armedProvider);
                    final fgService = ForegroundServiceManager();

                    if (newArmedState) {
                      await fgService.start();
                      ref
                          .read(serviceRunningProvider.notifier)
                          .setServiceRunning(true);
                      developer.log('Service Started via UI', name: 'BARQ_X');
                    } else {
                      await fgService.stop();
                      ref
                          .read(serviceRunningProvider.notifier)
                          .setServiceRunning(false);
                      developer.log('Service Stopped via UI', name: 'BARQ_X');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, // More generous horizontal padding
                      vertical: 14,   // Slightly taller for better tactile feel
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.black, width: 3.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(8, 8), // Consistent 8px hard shadow
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArmed ? 'DISARM SYSTEM' : 'ARM ENGINE',
                          style: const TextStyle(
                            fontSize: 13, // Slightly larger for readability
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.power_settings_new,
                          color: isArmed ? Colors.red[700] : AppColors.textPrimary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. CARD 2: GESTURE PALETTE (Professional Peach Layout)
  // Enhanced spacing and hierarchy for Neo-Brutalist precision
  // ============================================================
  Widget _buildProtocolPaletteCard(dynamic settings) {
    final activeCount = _countActiveProtocols(settings);

    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFFFCCB6)), // Peach
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24), // Professional asymmetric padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with enhanced typography
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GESTURE PROTOCOLS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900, // Heavier weight
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  '$activeCount ACTIVE',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // More generous spacing
          // Palette Grid: 5 circles with improved spacing
          Wrap(
            spacing: 16, // More generous spacing between circles
            runSpacing: 16,
            children: [
              // 1. SHAKE - Torch
              _buildProtocolCircle(
                icon: Icons.flashlight_on,
                color: AppColors.cardShake,
                isEnabled: settings.shakeEnabled,
                onTap: () => ref.read(settingsProvider.notifier).toggleShake(),
              ),
              // 2. TWIST - Camera
              _buildProtocolCircle(
                icon: Icons.camera_alt,
                color: AppColors.cardTwist,
                isEnabled: settings.twistEnabled,
                onTap: () => ref.read(settingsProvider.notifier).toggleTwist(),
              ),
              // 3. FLIP - DND
              _buildProtocolCircle(
                icon: Icons.notifications_off,
                color: AppColors.cardFlip,
                isEnabled: settings.flipEnabled,
                onTap: () => ref.read(settingsProvider.notifier).toggleFlip(),
              ),
              // 4. SECRET STRIKE - Custom Action
              _buildSecretStrikeCircle(settings),
              // 5. POCKET SHIELD - Protection
              _buildProtocolCircle(
                icon: Icons.security,
                color: AppColors.cardShield,
                isEnabled: settings.pocketShieldEnabled,
                onTap: () => ref.read(settingsProvider.notifier).togglePocketShield(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Secret Strike circle with special interaction and consistent border weight
  /// Tap: Opens custom action selector bottom sheet
  Widget _buildSecretStrikeCircle(dynamic settings) {
    return GestureDetector(
      onTap: () => _showSecretStrikeActionSheet(context, settings),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: settings.backTapEnabled ? AppColors.cardBackTap : Colors.grey[300],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 3.5), // Consistent border weight
        ),
        child: Icon(
          Icons.touch_app,
          size: 22,
          color: settings.backTapEnabled ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }

  /// Enhanced protocol circle with consistent Neo-Brutalist borders
  Widget _buildProtocolCircle({
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isEnabled ? color : Colors.grey[300],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 3.5), // Consistent 3.5px border
        ),
        child: Icon(
          icon,
          size: 36, // Chunky 36px for industrial look
          color: isEnabled ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }

  int _countActiveProtocols(dynamic settings) {
    int count = 0;
    if (settings.shakeEnabled) count++;
    if (settings.twistEnabled) count++;
    if (settings.flipEnabled) count++;
    if (settings.backTapEnabled) count++;
    if (settings.pocketShieldEnabled) count++;
    return count;
  }

  // ============================================================
  // SECRET STRIKE CUSTOM ACTION BOTTOM SHEET
  // White background, 3.5px black border, 0px radius
  // ============================================================
  void _showSecretStrikeActionSheet(BuildContext context, dynamic settings) {
    final currentAction = settings.backTapCustomAction;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make transparent to show our custom container
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero, // 0px radius - sharp edges
            border: Border(
              top: BorderSide(color: Colors.black, width: 3.5),
              left: BorderSide(color: Colors.black, width: 3.5),
              right: BorderSide(color: Colors.black, width: 3.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'SECRET STRIKE ACTION',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose what happens when you double-tap the back of your phone',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Option 1: WhatsApp
                _buildCustomActionOption(
                  context,
                  icon: Icons.chat,
                  title: 'LAUNCH WHATSAPP',
                  value: 'whatsapp',
                  currentValue: currentAction,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setBackTapAction('whatsapp');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                
                // Option 2: Google Assistant
                _buildCustomActionOption(
                  context,
                  icon: Icons.mic,
                  title: 'GOOGLE VOICE ASSISTANT',
                  value: 'assistant',
                  currentValue: currentAction,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setBackTapAction('assistant');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                
                // Option 3: Media Player
                _buildCustomActionOption(
                  context,
                  icon: Icons.play_circle_outline,
                  title: 'MEDIA PLAYER (PAUSE/PLAY)',
                  value: 'media',
                  currentValue: currentAction,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setBackTapAction('media');
                    Navigator.pop(context);
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Custom action option tile
  /// Selected state: Sky Blue (#B4D7F1) background with checkmark
  Widget _buildCustomActionOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final isSelected = currentValue == value;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB4D7F1) : Colors.transparent, // Sky Blue
          borderRadius: BorderRadius.zero, // 0px radius
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 24, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 4. CARD 3: VERIFICATION CHECKLIST (Professional Lavender Layout)
  // Enhanced monospace formatting and tactical spacing
  // ============================================================
  Widget _buildVerificationCard(dynamic settings) {
    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFD7D4F1)), // Lavender
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24), // Professional asymmetric padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM VERIFICATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900, // Consistent heavy weight
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18), // More generous spacing
          _buildCheckItem('KINETIC SHAKE (TORCH)', settings.shakeEnabled),
          _buildCheckItem('INERTIAL TWIST (CAMERA)', settings.twistEnabled),
          _buildCheckItem('SURFACE FLIP (DND)', settings.flipEnabled),
          _buildCheckItem('SECRET STRIKE (CUSTOM)', settings.backTapEnabled),
          _buildCheckItem('POCKET SHIELD (PROTECTION)', settings.pocketShieldEnabled),
        ],
      ),
    );
  }

  /// Enhanced check item with improved monospace formatting
  Widget _buildCheckItem(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // More generous vertical spacing
      child: Row(
        children: [
          // Enhanced monospace checkbox with tactical background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: checked 
                  ? Colors.black.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: Colors.black.withOpacity(0.15), 
                width: checked ? 1 : 0
              ),
            ),
            child: Text(
              checked ? '[X]' : '[ ]',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 15, // Slightly larger for better readability
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12), // More generous spacing
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: checked 
                    ? AppColors.textPrimary 
                    : AppColors.textSecondary, // Visual state differentiation
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. RECENT TRIGGERS - "THE STICKER COLLECTION"
  // Overlapping shaped stickers with aggressive Neo-Brutalist styling
  // ============================================================
  Widget _buildRecentTriggersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Bold, letterSpacing 2.0 for aggressive design
        const Text(
          'RECENT TRIGGERS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2.0, // Wider spacing for aggressive design
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16), // Space before sticker collection
        // Overlapping sticker collection using Stack with Positioned
        SizedBox(
          height: 70, // Enough height for 60px stickers + overlap
          child: Stack(
            children: [
              // Sticker 1: Square Shape - Chop Gesture (Coral)
              Positioned(
                left: 0,
                top: 0,
                child: _buildStickerShape(
                  shape: StickerShape.square,
                  icon: Icons.flashlight_on,
                  color: AppColors.cardShake, // Coral Red
                ),
              ),
              // Sticker 2: Circle Shape - Twist Gesture (Mint/Periwinkle)
              Positioned(
                left: 40, // 20px overlap with square
                top: 10,
                child: _buildStickerShape(
                  shape: StickerShape.circle,
                  icon: Icons.notifications_off,
                  color: AppColors.cardFlip, // Periwinkle
                ),
              ),
              // Sticker 3: Star Shape - Strike Gesture (Sky Blue)
              Positioned(
                left: 80, // 20px overlap with circle
                top: 5,
                child: _buildStickerShape(
                  shape: StickerShape.star,
                  icon: Icons.power_settings_new,
                  color: AppColors.masterToggleActive, // Sky Blue
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build shaped sticker for the collection - random shapes with 32px icons
  Widget _buildStickerShape({
    required StickerShape shape,
    required IconData icon,
    required Color color,
  }) {
    Widget shapeWidget;
    
    switch (shape) {
      case StickerShape.square:
        shapeWidget = Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.zero, // Sharp square corners
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: Colors.black),
        );
        break;
      case StickerShape.circle:
        shapeWidget = Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 3.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: Colors.black),
        );
        break;
      case StickerShape.star:
        // Create star using CustomPaint
        shapeWidget = CustomPaint(
          size: const Size(60, 60),
          painter: StarShapePainter(color: color),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Icon(icon, size: 32, color: Colors.black),
            ),
          ),
        );
        break;
    }
    
    return shapeWidget;
  }



  // ============================================================
  // PREMIUM FAB
  // FloatingActionButton with 0px radius, Periwinkle, 3.5px border
  // ============================================================
  Widget _buildPremiumFAB() {
    return FloatingActionButton(
      onPressed: () => _showQuickActionsSheet(context),
      backgroundColor: const Color(0xFFA0A5FF), // Periwinkle
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // 0px radius - perfect square
        side: BorderSide(color: Colors.black, width: 3.5),
      ),
      child: const Icon(
        Icons.add,
        size: 30,
        color: Colors.black,
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS BOTTOM SHEET
  // White background, 3.5px black border, 0px radius
  // ============================================================
  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make transparent to show our custom container
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero, // 0px radius - sharp corners
            border: Border(
              top: BorderSide(color: Colors.black, width: 3.5),
              left: BorderSide(color: Colors.black, width: 3.5),
              right: BorderSide(color: Colors.black, width: 3.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildActionItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About BARQ X',
                  subtitle: 'v2.0 • Neo-Brutalist Design',
                ),
                const SizedBox(height: 12.0),
                _buildActionItem(
                  context,
                  icon: Icons.tune,
                  title: 'Gesture Sensitivity',
                  subtitle: 'Adjust detection thresholds',
                ),
                const SizedBox(height: 12.0),
                _buildActionItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Statistics',
                  subtitle: 'View gesture usage',
                ),
                const SizedBox(height: 12.0),
                _buildActionItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Learn more about gestures',
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero, // Sharp corners
        border: Border.all(color: AppColors.borderPrimary, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textPrimary),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
