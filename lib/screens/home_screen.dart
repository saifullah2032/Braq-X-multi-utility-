import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../models/gesture_event.dart';
import '../providers/armed_provider.dart';
import '../providers/settings_provider.dart';
import '../services/gesture_integration_service.dart';
import '../widgets/gesture_card.dart';

/// Home screen dashboard showing all 5 gestures
/// Master toggle + 5 gesture cards in 2x3 grid layout
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Master Toggle (Armed/Disarmed)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConfig.screenPadding,
                vertical: 16.0,
              ),
              child: GestureDetector(
                onTap: () async {
                  await ref.read(armedProvider.notifier).toggle();
                },
                child: Container(
                  height: AppConfig.masterToggleHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConfig.masterTogglePadding,
                  ),
                  decoration: BoxDecoration(
                    color: isArmed
                        ? AppColors.accentPrimary
                        : AppColors.accentQuaternary,
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
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
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
              ),
            ),

            // Gesture Cards Grid (5 gestures)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConfig.screenPadding,
                ),
                child: GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppConfig.cardSpacing,
                    crossAxisSpacing: AppConfig.cardSpacing,
                    childAspectRatio: 0.85,
                  ),
                  children: [
                    // Shake (Torch)
                    GestureCard(
                      gestureType: GestureType.shake,
                      isEnabled: settings.shakeEnabled && isArmed,
                      onToggle: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .toggleShake();
                      },
                    ),

                    // Twist (Camera)
                    GestureCard(
                      gestureType: GestureType.twist,
                      isEnabled: settings.twistEnabled && isArmed,
                      onToggle: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .toggleTwist();
                      },
                    ),

                    // Flip (DND)
                    GestureCard(
                      gestureType: GestureType.flip,
                      isEnabled: settings.flipEnabled && isArmed,
                      onToggle: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .toggleFlip();
                      },
                    ),

                    // Back-Tap (Strike)
                    GestureCard(
                      gestureType: GestureType.backTap,
                      isEnabled: settings.backTapEnabled && isArmed,
                      onToggle: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .toggleBackTap();
                      },
                      onCustomActionTap: () {
                        _showCustomActionSheet(context, ref);
                      },
                    ),

                    // Pocket Shield
                    GestureCard(
                      gestureType: GestureType.pocketShield,
                      isEnabled: settings.pocketShieldEnabled && isArmed,
                      onToggle: () async {
                        await ref
                            .read(settingsProvider.notifier)
                            .togglePocketShield();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConfig.screenPadding,
                vertical: 16.0,
              ),
              child: Text(
                'Tap toggles to enable/disable • Shake, Twist, Flip, Back-Tap, Protect',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show custom action selector for back-tap
  void _showCustomActionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.textPrimary,
              width: AppConfig.cardBorderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConfig.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SELECT BACK-TAP ACTION',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16.0),
              _buildActionOption(
                context,
                ref,
                'whatsapp',
                '💬 WhatsApp',
              ),
              SizedBox(height: 8.0),
              _buildActionOption(
                context,
                ref,
                'assistant',
                '🎤 Google Assistant',
              ),
              SizedBox(height: 8.0),
              _buildActionOption(
                context,
                ref,
                'media_player',
                '🎵 Media Player',
              ),
              SizedBox(height: 16.0),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textPrimary,
                      width: AppConfig.secondaryBorderWidth,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'CANCEL',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual action option
  Widget _buildActionOption(
    BuildContext context,
    WidgetRef ref,
    String actionType,
    String label,
  ) {
    return GestureDetector(
      onTap: () async {
        await ref
            .read(settingsProvider.notifier)
            .setBackTapAction(actionType);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Back-Tap set to $label'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textPrimary,
            width: AppConfig.secondaryBorderWidth,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
