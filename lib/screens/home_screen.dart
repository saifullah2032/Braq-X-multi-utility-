import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../providers/armed_provider.dart';
import '../providers/settings_provider.dart';
import '../services/gesture_integration_service.dart';
import '../widgets/neo_brutalist_background.dart';
import '../widgets/neo_brutalist_gesture_card.dart';
import '../widgets/sticker_badge.dart';
import '../widgets/master_toggle_card.dart';
import '../widgets/premium_fab.dart';
import '../widgets/dashboard_footer.dart';

/// Premium Single-Page Gesture-Utility Dashboard
/// Soft Neo-Brutalism + 2D Comic/Sticker aesthetic
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    developer.log('HomeScreen mounted', name: 'HomeScreen');

    // Initialize gesture integration on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('Starting gesture integration service initialization...', name: 'HomeScreen');
      try {
        ref.read(gestureIntegrationProvider).initialize().then((_) {
          developer.log('✓ Gesture integration service initialized successfully', name: 'HomeScreen');
        }).catchError((e, st) {
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

  @override
  Widget build(BuildContext context) {
    final isArmed = ref.watch(armedProvider);
    final settings = ref.watch(settingsProvider);

    return NeoBrutalistBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Main scrollable content
              SingleChildScrollView(
                padding: EdgeInsets.all(AppConfig.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title
                    Text(
                      'BARQ X',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 44,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Master Toggle Card
                    MasterToggleCard(
                      isArmed: isArmed,
                      onToggle: () async {
                        await ref.read(armedProvider.notifier).toggle();
                      },
                    ),
                    const SizedBox(height: 32.0),

                    // Gesture Protocols with Sticker Badge on first card
                    Stack(
                      children: [
                        // Cards container
                        Column(
                          children: [
                            // Card 1: Shake with Sticker Badge
                            _buildGestureCard(
                              context,
                              emoji: '🔦',
                              title: 'SHAKE PROTOCOL',
                              description: 'KINETIC SHAKE',
                              cardColor: AppColors.cardShake,
                              isEnabled: settings.shakeEnabled && isArmed,
                              onToggle: () async {
                                await ref.read(settingsProvider.notifier).toggleShake();
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Card 2: Twist
                            _buildGestureCard(
                              context,
                              emoji: '📷',
                              title: 'TWIST PROTOCOL',
                              description: 'INERTIAL TWIST',
                              cardColor: AppColors.cardTwist,
                              isEnabled: settings.twistEnabled && isArmed,
                              onToggle: () async {
                                await ref.read(settingsProvider.notifier).toggleTwist();
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Card 3: Flip
                            _buildGestureCard(
                              context,
                              emoji: '🔕',
                              title: 'FLIP PROTOCOL',
                              description: 'SURFACE FLIP',
                              cardColor: AppColors.cardFlip,
                              isEnabled: settings.flipEnabled && isArmed,
                              onToggle: () async {
                                await ref.read(settingsProvider.notifier).toggleFlip();
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Card 4: Strike
                            _buildGestureCard(
                              context,
                              emoji: '⚡',
                              title: 'STRIKE PROTOCOL',
                              description: 'SECRET STRIKE',
                              cardColor: AppColors.cardBackTap,
                              isEnabled: settings.backTapEnabled && isArmed,
                              onToggle: () async {
                                await ref.read(settingsProvider.notifier).toggleBackTap();
                              },
                              onCustomAction: () {
                                _showCustomActionSheet(context, ref);
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Card 5: Shield
                            _buildGestureCard(
                              context,
                              emoji: '🛡️',
                              title: 'POCKET SHIELD',
                              description: 'PROTECTION ACTIVE',
                              cardColor: AppColors.cardShield,
                              isEnabled: settings.pocketShieldEnabled && isArmed,
                              onToggle: () async {
                                await ref.read(settingsProvider.notifier).togglePocketShield();
                              },
                            ),
                          ],
                        ),

                        // Sticker badge positioned on first card
                        Positioned(
                          right: -12,
                          top: -8,
                          child: StickerBadge(),
                        ),
                      ],
                    ),

                    // Footer
                    DashboardFooter(),

                    // Extra padding for FAB
                    const SizedBox(height: 80.0),
                  ],
                ),
              ),

              // Floating Action Button (bottom right)
              Positioned(
                bottom: 24,
                right: 24,
                child: PremiumFAB(
                  onPressed: () {
                    _showSettingsBottomSheet(context, ref);
                  },
                  backgroundColor: const Color(0xFFBCB1DE), // Lavender
                  icon: Icons.settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual gesture protocol card
  Widget _buildGestureCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String description,
    required Color cardColor,
    required bool isEnabled,
    required VoidCallback onToggle,
    VoidCallback? onCustomAction,
  }) {
    return NeoBrutalistGestureCard(
      title: title,
      description: description,
      emoji: emoji,
      cardColor: cardColor,
      isEnabled: isEnabled,
      onToggle: onToggle,
      onCustomAction: onCustomAction,
    );
  }

  /// Show settings bottom sheet from FAB
  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(
          color: AppColors.borderPrimary,
          width: 3.5,
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20.0),

              // Settings options
              _buildSettingItem(
                context,
                icon: '🎨',
                title: 'About BARQ X',
                subtitle: 'v2.0 • Neo-Brutalist Design',
              ),
              const SizedBox(height: 12.0),

              _buildSettingItem(
                context,
                icon: '⚙️',
                title: 'Gesture Sensitivity',
                subtitle: 'Adjust detection thresholds',
              ),
              const SizedBox(height: 12.0),

              _buildSettingItem(
                context,
                icon: '📊',
                title: 'Statistics',
                subtitle: 'View gesture usage',
              ),
              const SizedBox(height: 12.0),

              _buildSettingItem(
                context,
                icon: '❓',
                title: 'Help & Support',
                subtitle: 'Learn more about gestures',
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        );
      },
    );
  }

  /// Build individual setting item
  Widget _buildSettingItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  /// Show custom action selector for back-tap
  void _showCustomActionSheet(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(
          color: AppColors.borderPrimary,
          width: 3.5,
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT CUSTOM ACTION FOR STRIKE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildActionOption(
                context,
                icon: '📷',
                label: 'Camera',
                value: 'camera',
                currentValue: settings.backTapCustomAction,
                onSelect: () {
                  ref.read(settingsProvider.notifier).setBackTapAction('camera');
                  Navigator.pop(context);
                },
              ),
              _buildActionOption(
                context,
                icon: '💬',
                label: 'WhatsApp',
                value: 'whatsapp',
                currentValue: settings.backTapCustomAction,
                onSelect: () {
                  ref.read(settingsProvider.notifier).setBackTapAction('whatsapp');
                  Navigator.pop(context);
                },
              ),
              _buildActionOption(
                context,
                icon: '🎤',
                label: 'Google Assistant',
                value: 'assistant',
                currentValue: settings.backTapCustomAction,
                onSelect: () {
                  ref.read(settingsProvider.notifier).setBackTapAction('assistant');
                  Navigator.pop(context);
                },
              ),
              _buildActionOption(
                context,
                icon: '🎵',
                label: 'Media Player',
                value: 'media',
                currentValue: settings.backTapCustomAction,
                onSelect: () {
                  ref.read(settingsProvider.notifier).setBackTapAction('media');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build action option for custom action sheet
  Widget _buildActionOption(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required String currentValue,
    required VoidCallback onSelect,
  }) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.masterToggleActive : Colors.transparent,
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12.0),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
