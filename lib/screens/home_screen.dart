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
/// 100% Fidelity Systems Design with wide-ruled notebook and icon sticker pile
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
          child: Stack(
            children: [
              // Main content with indented gutter rule
              SingleChildScrollView(
                physics:
                    const ClampingScrollPhysics(), // Updated to ClampingScrollPhysics for taller content
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    return Padding(
                      // Indented Gutter Rule: ALL content shifted right of red margin (10% + 20px buffer)
                      padding: EdgeInsets.only(
                        left:
                            screenWidth * 0.10 +
                            20, // 10% + 20px buffer after gutter
                        right: 16,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ========================================
                          // 1. HEADER SECTION (indented with gutter)
                          // ========================================
                          _buildGutterTitle(),
                          const SizedBox(
                            height: 36,
                          ), // "Squash" Fix: 36px between sections
                          // ========================================
                          // 2. CARD 1: MAIN STATUS & ARMING (Blue)
                          // ========================================
                          _buildStatusCard(
                            context,
                            ref,
                            isArmed: isArmed,
                            isServiceRunning: isServiceRunning,
                          ),
                          const SizedBox(
                            height: 36,
                          ), // "Squash" Fix: 36px between cards
                          // ========================================
                          // 3. CARD 2: GESTURE PALETTE (Peach)
                          // ========================================
                          _buildProtocolPaletteCard(settings),
                          const SizedBox(
                            height: 36,
                          ), // "Squash" Fix: 36px between cards
                          // ========================================
                          // 4. CARD 3: VERIFICATION CHECKLIST (Lavender)
                          // ========================================
                          /*_buildVerificationCard(settings),
                          const SizedBox(
                            height: 36,
                          ),*/
                          // "Squash" Fix: 36px before triggers
                          // ========================================
                          // 5. RECENT TRIGGERS SECTION
                          // ========================================
                          _buildRecentTriggersSection(),
                          const SizedBox(
                            height: 100,
                          ), // Space for FAB and scroll area
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Star Icon: Ignores gutter padding - absolute positioned
              _buildAbsoluteHeaderStar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. NOTEBOOK GUTTER HEADER - God-Tier UI/UX Architecture
  // Title positioned in gutter area, Star absolute positioned as bookmark
  // ============================================================
  Widget _buildGutterTitle() {
    return const Text(
      'BARQ X', // Strictly "BARQ X" uppercase
      style: TextStyle(
        fontFamily: 'Bebas Neue',
        fontSize: 46, // Keep large bold uppercase style
        fontWeight: FontWeight.bold,
        height: 1.5, // Tighter line height for aggressive look
        letterSpacing: 2.5, // Aggressive letter spacing
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Absolute positioned header star - acts like a bookmark pinned to page edge
  Widget _buildAbsoluteHeaderStar() {
    return Positioned(
      top: 10, // Updated to exact specification
      right: 10, // Updated to exact specification
      child: Container(
        padding: const EdgeInsets.all(12), // Generous padding
        decoration: _brutalistDecoration(const Color(0xFFFFCCB6)), // Peach
        child: const Icon(
          Icons.star_rounded,
          size: 28, // Maintain size for balance
          color: AppColors.textPrimary,
        ),
      ),
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
            top: 75,
            child: Icon(
              Icons.bolt,
              size: 85, // Slightly larger for more presence
              color: Colors.white60, // More subtle opacity for tactical feel
            ),
          ),
          // Sticker Badge (overlapping corner)
          const Positioned(right: -6, top: -6, child: StickerBadge()),
          // Main tactical content with precise spacing
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              22,
              24,
              24,
            ), // Asymmetric padding for tactical hierarchy
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "ACTIVE ENGINE:" tactical label
                const Text(
                  'ACTIVE ENGINE:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900, // Heavier weight for tactical feel
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16), // Tight spacing for hierarchy
                // "BARQ X GESTURE SYSTEM" main title
                const Text(
                  'BARQ X GESTURE SYSTEM',
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 28, // Slightly larger for more impact
                    letterSpacing: 1.5,
                    height: 0.9,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10), // Controlled spacing
                // Status description with tactical formatting
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.1,
                    ), // Subtle background for tactical readout
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.2),
                      width: 1,
                    ),
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
                      vertical: 14, // Slightly taller for better tactile feel
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
                          color: isArmed
                              ? Colors.red[700]
                              : AppColors.textPrimary,
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
  // 3. CARD 2: MYTHIC PROTOCOL LEGEND (Multi-Row Layout)
  // Grid-style list with 42x42 icon boxes and mythic name labels
  // ============================================================
  Widget _buildProtocolPaletteCard(dynamic settings) {
    final activeCount = _countActiveProtocols(settings);

    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFFFCCB6)), // Peach
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        24,
      ), // Professional asymmetric padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with enhanced typography
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MYTHIC PROTOCOL LEGEND',
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
                  border: Border.all(
                    color: Colors.black.withOpacity(0.2),
                    width: 1,
                  ),
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
          // Multi-row layout with text labels
          Column(
            children: [
              // 1. BOLT IGNITION
              _buildProtocolRow(
                icon: Icons.flashlight_on,
                label: 'BOLT IGNITION (Torch)',
                color: AppColors.cardShake,
                isEnabled: settings.shakeEnabled,
                onTap: () => ref.read(settingsProvider.notifier).toggleShake(),
              ),
              const SizedBox(height: 12), // 12px spacing between protocol rows
              // 2. HERMES SNAP
              _buildProtocolRow(
                icon: Icons.camera_alt,
                label: 'HERMES SNAP (Camera)',
                color: AppColors.cardTwist,
                isEnabled: settings.twistEnabled,
                onTap: () => ref.read(settingsProvider.notifier).toggleTwist(),
              ),
              const SizedBox(height: 12), // 12px spacing between protocol rows
              // 3. HORIZON LOCK
              _buildProtocolRow(
                icon: Icons.notifications_off,
                label: 'HORIZON LOCK (DND)',
                color: AppColors.cardFlip,
                isEnabled: settings.flipEnabled,
                onTap: () => ref.read(settingsProvider.notifier).toggleFlip(),
              ),
              const SizedBox(height: 12), // 12px spacing between protocol rows
              // 4. OMEGA TRIGGER
              _buildOmegaTriggerRow(settings),
              const SizedBox(height: 12), // 12px spacing between protocol rows
              // 5. GHOST VEIL
              _buildProtocolRow(
                icon: Icons.security,
                label: 'GHOST VEIL (Pocket mode)',
                color: AppColors.cardShield,
                isEnabled: settings.pocketShieldEnabled,
                onTap: () =>
                    ref.read(settingsProvider.notifier).togglePocketShield(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Omega Trigger circle with special interaction and consistent border weight
  Widget _buildOmegaTriggerCircle(dynamic settings) {
    return GestureDetector(
      onTap: () => _showOmegaTriggerActionSheet(context, settings),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: settings.backTapEnabled
              ? AppColors.cardBackTap
              : Colors.grey[300],
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black,
            width: 3.5,
          ), // Consistent border weight
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
          border: Border.all(
            color: Colors.black,
            width: 3.5,
          ), // Consistent 3.5px border
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

  /// Protocol row with 42x42 icon box and mythic name label
  Widget _buildProtocolRow({
    required IconData icon,
    required String label,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // 42x42 Icon Box with 2.5px black border
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEnabled ? color : Colors.grey[300],
              borderRadius: BorderRadius.zero, // 0px radius sharp corners
              border: Border.all(
                color: Colors.black,
                width: 2.5, // 2.5px border as specified
              ),
            ),
            child: Icon(
              icon,
              size: 24, // Appropriate icon size for 42x42 box
              color: isEnabled ? Colors.black : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16), // Spacing between icon and label
          // Mythic Name Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14, // Size 14 as specified
                fontWeight: FontWeight.bold, // Bold text
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Omega Trigger row with special interaction
  Widget _buildOmegaTriggerRow(dynamic settings) {
    return GestureDetector(
      onTap: () => _showOmegaTriggerActionSheet(context, settings),
      child: Row(
        children: [
          // 42x42 Icon Box with 2.5px black border
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: settings.backTapEnabled
                  ? AppColors.cardBackTap
                  : Colors.grey[300],
              borderRadius: BorderRadius.zero, // 0px radius sharp corners
              border: Border.all(
                color: Colors.black,
                width: 2.5, // 2.5px border as specified
              ),
            ),
            child: Icon(
              Icons.touch_app,
              size: 24, // Appropriate icon size for 42x42 box
              color: settings.backTapEnabled ? Colors.black : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16), // Spacing between icon and label
          // Mythic Name Label
          const Expanded(
            child: Text(
              'OMEGA TRIGGER (Double Tap/Custom)',
              style: TextStyle(
                fontSize: 14, // Size 14 as specified
                fontWeight: FontWeight.bold, // Bold text
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OMEGA TRIGGER CUSTOM ACTION BOTTOM SHEET
  // White background, 3.5px black border, 0px radius
  // ============================================================
  void _showOmegaTriggerActionSheet(BuildContext context, dynamic settings) {
    final currentAction = settings.backTapCustomAction;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Make transparent to show our custom container
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
                  'OMEGA TRIGGER ACTION',
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
                    ref
                        .read(settingsProvider.notifier)
                        .setBackTapAction('whatsapp');
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
                    ref
                        .read(settingsProvider.notifier)
                        .setBackTapAction('assistant');
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
                    ref
                        .read(settingsProvider.notifier)
                        .setBackTapAction('media');
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
          color: isSelected
              ? const Color(0xFFB4D7F1)
              : Colors.transparent, // Sky Blue
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

  /*// ============================================================
  // 4. CARD 3: VERIFICATION CHECKLIST (Professional Lavender Layout)
  // Enhanced monospace formatting and tactical spacing
  // ============================================================
  Widget _buildVerificationCard(dynamic settings) {
    return Container(
      width: double.infinity,
      decoration: _brutalistDecoration(const Color(0xFFD7D4F1)), // Lavender
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        24,
      ), // Professional asymmetric padding
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
          _buildCheckItem('BOLT IGNITION', settings.shakeEnabled),
          _buildCheckItem('HERMES SNAP', settings.twistEnabled),
          _buildCheckItem('HORIZON LOCK', settings.flipEnabled),
          _buildCheckItem('OMEGA TRIGGER', settings.backTapEnabled),
          _buildCheckItem('GHOST VEIL', settings.pocketShieldEnabled),
        ],
      ),
    );
  }

  /// Enhanced check item with improved monospace formatting
  Widget _buildCheckItem(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // More generous vertical spacing
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
                width: checked ? 1 : 0,
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
  }*/

  // ============================================================
  // 5. RECENT TRIGGERS - "THE SPACED STICKER PILE"
  // Horizontal row with mythological themes and precise 12px spacing
  // ============================================================
  Widget _buildRecentTriggersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Bold, letterSpacing 2.0 for God-Tier design
        const Text(
          'RECENT TRIGGERS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2.0, // Wider spacing for mythological theme
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16), // Space before spaced sticker pile
        // Horizontal row with Wrap - 12px spacing between 64x64 squares
        Wrap(
          spacing: 12, // 12px spacing as specified
          runSpacing: 12, // Vertical spacing between rows
          children: [
            // BOLT IGNITION - Mythological Torch
            _buildMythologicalStickerCard(
              icon: Icons.flashlight_on,
              color: AppColors.cardShake, // Coral Red
            ),
            // HERMES SNAP - Mythological Camera
            _buildMythologicalStickerCard(
              icon: Icons.camera_alt,
              color: AppColors.cardTwist, // Mint/Teal
            ),
            // HORIZON LOCK - Mythological DND
            _buildMythologicalStickerCard(
              icon: Icons.notifications_off,
              color: AppColors.cardFlip, // Periwinkle
            ),
          ],
        ),
      ],
    );
  }

  /// Mythological sticker card - 64x64 square with 0px radius, 3.5px border
  /// Large 34px centered icon only, mythological color background
  Widget _buildMythologicalStickerCard({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 64, // 64x64 square as specified
      height: 64,
      decoration: BoxDecoration(
        color: color, // Mythological gesture-specific color
        borderRadius: BorderRadius.zero, // 0px radius sharp corners
        border: Border.all(
          color: Colors.black,
          width: 3.5,
        ), // 3.5px black border
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6), // 6px shadow as specified
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 34, // 34px centered icon for 64x64 square
        color: Colors.black, // Black icons for high contrast
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
      child: const Icon(Icons.add, size: 30, color: Colors.black),
    );
  }

  // ============================================================
  // QUICK ACTIONS BOTTOM SHEET
  // White background, 3.5px black border, 0px radius
  // ============================================================
  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Make transparent to show our custom container
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
