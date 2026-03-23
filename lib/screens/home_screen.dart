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
import '../widgets/status_banner.dart';

/// Home screen dashboard - High-fidelity neo-brutalist design
/// Master toggle + 5 gesture protocol cards with hard shadows and chunky borders
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
    // Cleanup on unmount
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppConfig.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Title + Subtitle
                  _buildHeader(context, isArmed),
                  const SizedBox(height: 24.0),

                  // Master Toggle Button
                  _buildMasterToggle(context, isArmed),
                  const SizedBox(height: 32.0),

                  // 5 Gesture Protocol Cards
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
                  const SizedBox(height: 32.0),

                  // Status Banner at bottom
                  Center(
                    child: StatusBanner(),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with title and subtitle
  Widget _buildHeader(BuildContext context, bool isArmed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BARQ X',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 40,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'GESTURE SYSTEM: ${isArmed ? 'ARMED' : 'DISARMED'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isArmed ? AppColors.masterToggleActive : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }

  /// Build massive chunky master toggle button
  Widget _buildMasterToggle(BuildContext context, bool isArmed) {
    return GestureDetector(
      onTap: () async {
        await ref.read(armedProvider.notifier).toggle();
      },
      child: Stack(
        children: [
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

          // Main toggle button
          Container(
            height: AppConfig.masterToggleHeight,
            padding: EdgeInsets.symmetric(
              horizontal: AppConfig.masterTogglePadding,
            ),
            decoration: BoxDecoration(
              color: isArmed ? AppColors.masterToggleActive : AppColors.background,
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 3.5, // Chunky 3.5px border
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArmed ? 'BARQ X ARMED' : 'BARQ X DISARMED',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isArmed ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                ),
                AnimatedRotation(
                  turns: isArmed ? 0.5 : 0.0,
                  duration: AppConfig.toggleTransitionDuration,
                  child: Icon(
                    Icons.power_settings_new,
                    color: isArmed ? Colors.white : AppColors.textSecondary,
                    size: 28.0,
                  ),
                ),
              ],
            ),
          ),
        ],
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
