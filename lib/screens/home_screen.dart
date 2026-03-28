import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../constants/app_colors.dart';
import '../providers/armed_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/service_running_provider.dart';
import '../services/gesture_integration_service.dart';
import '../services/foreground_service_manager.dart';
import '../services/disarm_broadcast_service.dart';
import '../widgets/neo_brutalist_background.dart';
import '../widgets/sticker_badge.dart';

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
            physics: const ClampingScrollPhysics(), // Eliminates bounce/overscroll
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========================================
                // 1. HEADER SECTION
                // ========================================
                _buildHeader(),
                const SizedBox(height: 24),

                // ========================================
                // 2. CARD 1: MAIN STATUS & ARMING (Blue)
                // ========================================
                _buildStatusCard(
                  context,
                  ref,
                  isArmed: isArmed,
                  isServiceRunning: isServiceRunning,
                ),
                const SizedBox(height: 16),

                // ========================================
                // 3. CARD 2: GESTURE PALETTE (Peach)
                // ========================================
                _buildProtocolPaletteCard(settings),
                const SizedBox(height: 16),

                // ========================================
                // 4. CARD 3: VERIFICATION CHECKLIST (Lavender)
                // ========================================
                _buildVerificationCard(settings),
                const SizedBox(height: 16), // Reduced from 24 to 16

                // ========================================
                // 5. RECENT TRIGGERS SECTION
                // ========================================
                _buildRecentTriggersSection(),
                
                const SizedBox(height: 80), // Space for FAB only
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. HEADER & TITLE
  // Row: Title + Spacer + Folder Icon
  // ============================================================
  Widget _buildHeader() {
    return Row(
      children: [
        // Title: "BARQ X CONTROL\nCENTER"
        const Text(
          'BARQ X CONTROL\nCENTER',
          style: TextStyle(
            fontFamily: 'Bebas Neue',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 0.9,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        // Folder Icon: Peach container, 3.5px border, 8px shadow
        Container(
          padding: const EdgeInsets.all(10),
          decoration: _brutalistDecoration(const Color(0xFFFFCCB6)), // Peach
          child: const Icon(
            Icons.folder_open,
            size: 26,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 2. CARD 1: MAIN STATUS & ARMING (The Blue Card)
  // Sky Blue (#B4D7F1), full-width Stack
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
          // Large bolt icon (far right, background)
          const Positioned(
            right: 10,
            top: 10,
            child: Icon(
              Icons.bolt,
              size: 80,
              color: Colors.white70,
            ),
          ),
          // Sticker Badge (top-right corner)
          const Positioned(
            right: -5,
            top: -5,
            child: StickerBadge(),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "ACTIVE ENGINE:" label
                const Text(
                  'ACTIVE ENGINE:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // "BARQ X GESTURE SYSTEM" title
                const Text(
                  'BARQ X GESTURE SYSTEM',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 28,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Status description
                Text(
                  isArmed
                      ? 'MASTERED KINETIC INTEGRATION'
                      : 'SYSTEM STANDBY - DISARMED',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Master Toggle Button (White, 0px radius, 8px shadow)
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: _brutalistDecoration(Colors.white),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArmed ? 'DISARM SYSTEM' : 'ARM ENGINE',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.power_settings_new,
                          color: isArmed ? Colors.red : AppColors.textPrimary,
                          size: 20,
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
  // 3. CARD 2: GESTURE PALETTE (The Peach Card)
  // Peach (#FFCCB6), sharp edges
  // Secret Strike (touch_app) opens custom action selector
  // ============================================================
  Widget _buildProtocolPaletteCard(dynamic settings) {
    final activeCount = _countActiveProtocols(settings);

    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFFFCCB6)), // Peach
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GESTURE PROTOCOLS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$activeCount ACTIVE',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Palette Grid: 5 circles
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
              // 4. SECRET STRIKE - Custom Action (Special: Long press for options)
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

  /// Secret Strike circle with special interaction
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
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Icon(
          Icons.touch_app,
          size: 22,
          color: settings.backTapEnabled ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }

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
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Icon(
          icon,
          size: 22,
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
  // 4. CARD 3: VERIFICATION CHECKLIST (The Lavender Card)
  // Lavender (#D7D4F1), sharp edges
  // ============================================================
  Widget _buildVerificationCard(dynamic settings) {
    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFD7D4F1)), // Lavender
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM VERIFICATION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckItem('KINETIC SHAKE (TORCH)', settings.shakeEnabled),
          _buildCheckItem('INERTIAL TWIST (CAMERA)', settings.twistEnabled),
          _buildCheckItem('SURFACE FLIP (DND)', settings.flipEnabled),
          _buildCheckItem('SECRET STRIKE (CUSTOM)', settings.backTapEnabled),
          _buildCheckItem('POCKET SHIELD (PROTECTION)', settings.pocketShieldEnabled),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            checked ? '[X]' : '[ ]',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. RECENT TRIGGERS SECTION
  // Title aligned with BARQ X header (left edge)
  // Sticker row with 0 left padding for alignment
  // ============================================================
  Widget _buildRecentTriggersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Bold, letterSpacing 1.5, left-aligned with header
        const Text(
          'RECENT TRIGGERS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Sticker row: padding 0 on left for alignment
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero, // No left padding
          child: Row(
            children: [
              _buildTriggerNote('SHAKE DETECTED', AppColors.cardShake),
              _buildTriggerNote('DND ACTIVATED', AppColors.cardFlip),
              _buildTriggerNote('ENGINE ARMED', AppColors.masterToggleActive),
            ],
          ),
        ),
      ],
    );
  }

  /// Trigger note sticker
  /// 3.5px black border, 0px radius, 4px hard shadow
  Widget _buildTriggerNote(String text, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero, // 0px radius - sharp corners
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4), // 4px hard shadow
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
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
