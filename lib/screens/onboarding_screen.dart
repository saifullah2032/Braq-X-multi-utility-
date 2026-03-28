import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/runtime_permissions_service.dart';
import '../services/dnd_permission_service.dart';

/// Professional 4-step mandatory onboarding
/// Clean Neo-Brutalist design with unified permission flow
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isRequestingPermissions = false;

  // Permission states
  bool _cameraGranted = false;
  bool _notificationGranted = false;
  bool _systemAlertGranted = false;
  bool _dndAccessGranted = false;
  bool _batteryOptimizationGranted = false;

  final _runtimePermissions = RuntimePermissionsService();
  final _dndPermissions = DndPermissionService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkPermissionStates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Check all permission states
  Future<void> _checkPermissionStates() async {
    final camera = await _runtimePermissions.checkCamera();
    final notification = await _runtimePermissions.checkPostNotifications();
    final systemAlert = await _runtimePermissions.checkSystemAlertWindow();
    final dndAccess = await _dndPermissions.hasNotificationPolicyAccess();

    if (mounted) {
      setState(() {
        _cameraGranted = camera;
        _notificationGranted = notification;
        _systemAlertGranted = systemAlert;
        _dndAccessGranted = dndAccess;
      });
    }
  }

  /// Request all permissions sequentially with progress feedback
  Future<void> _requestAllPermissions() async {
    setState(() => _isRequestingPermissions = true);

    try {
      // 1. Camera permission
      await _runtimePermissions.checkCamera();
      await _checkPermissionStates();
      await Future.delayed(const Duration(milliseconds: 300));

      // 2. Notification permission
      await _runtimePermissions.checkPostNotifications();
      await _checkPermissionStates();
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. System Alert Window
      await _runtimePermissions.checkSystemAlertWindow();
      await _checkPermissionStates();
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. DND Access (opens settings)
      if (!_dndAccessGranted) {
        await _dndPermissions.requestNotificationPolicyAccess();
      }
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkPermissionStates();

      // 5. Battery Optimization (opens settings)
      await _runtimePermissions.requestIgnoreBatteryOptimizations();
      await Future.delayed(const Duration(milliseconds: 500));

      // Final check
      await _checkPermissionStates();
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermissions = false);
      }
    }
  }

  /// Check if all critical permissions are granted
  bool get _allCriticalPermissionsGranted {
    return _cameraGranted &&
        _notificationGranted &&
        _systemAlertGranted &&
        _dndAccessGranted;
  }

  int get _grantedPermissionCount {
    int count = 0;
    if (_cameraGranted) count++;
    if (_notificationGranted) count++;
    if (_systemAlertGranted) count++;
    if (_dndAccessGranted) count++;
    if (_batteryOptimizationGranted) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressBar(),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildGesturesPage(),
                  _buildPermissionsPage(),
                  _buildReadyPage(),
                ],
              ),
            ),

            // Navigation
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  /// Progress bar showing current step
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;
          return Expanded(
            child: Container(
              height: 6.0,
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.successGreen
                    : isActive
                        ? AppColors.accentPrimary
                        : AppColors.toggleDisarmed,
                borderRadius: BorderRadius.circular(3.0),
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 1.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Navigation bar with back/next buttons
  Widget _buildNavigationBar() {
    final canProceed = _currentPage < 2 ||
        (_currentPage == 2 && _allCriticalPermissionsGranted) ||
        _currentPage == 3;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderPrimary,
            width: 2.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentPage > 0)
            _buildNavButton(
              'BACK',
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              isPrimary: false,
            )
          else
            const SizedBox(width: 80),

          // Step indicator
          Text(
            '${_currentPage + 1} / 4',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          // Next/Start button
          _buildNavButton(
            _currentPage == 3 ? 'START' : 'NEXT',
            onTap: canProceed
                ? () {
                    if (_currentPage < 3) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.onComplete();
                    }
                  }
                : null,
            isPrimary: true,
            isEnabled: canProceed,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    String label, {
    VoidCallback? onTap,
    bool isPrimary = false,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isEnabled ? AppColors.accentPrimary : AppColors.toggleDisarmed)
              : Colors.transparent,
          border: Border.all(
            color: AppColors.borderPrimary,
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isPrimary
                    ? Colors.white
                    : (isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
        ),
      ),
    );
  }

  /// Page 1: Welcome
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo/Title
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.cardShake,
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 3.5,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Text(
              '🔦',
              style: TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'BARQ X',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                  letterSpacing: 4,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 2,
              ),
            ),
            child: Text(
              'GESTURE UTILITY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 2,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Control your Android device with intuitive gestures. No buttons, no menus - just natural motion.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Feature preview
          _buildFeaturePreview(),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview() {
    final features = [
      {'emoji': '🔦', 'name': 'Torch', 'action': 'Shake'},
      {'emoji': '📷', 'name': 'Camera', 'action': 'Twist'},
      {'emoji': '🔕', 'name': 'DND', 'action': 'Flip'},
      {'emoji': '⚡', 'name': 'Custom', 'action': 'Strike'},
      {'emoji': '🛡️', 'name': 'Shield', 'action': 'Pocket'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Text(f['emoji']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    f['name']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.toggleDisarmed,
                    border: Border.all(color: AppColors.borderPrimary, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    f['action']!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Page 2: Gestures explanation
  Widget _buildGesturesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'HOW IT WORKS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 24),
          _buildStepCard('1', 'ARM THE SYSTEM',
              'Enable BARQ X with the master toggle on the home screen.'),
          const SizedBox(height: 12),
          _buildStepCard('2', 'CONFIGURE GESTURES',
              'Choose which gestures to enable. All are active by default.'),
          const SizedBox(height: 12),
          _buildStepCard('3', 'PERFORM GESTURE',
              'Shake, twist, flip or tap - each triggers a specific action.'),
          const SizedBox(height: 12),
          _buildStepCard('4', 'INSTANT FEEDBACK',
              'Feel haptic confirmation as your action executes immediately.'),
          const SizedBox(height: 12),
          _buildStepCard('5', 'BACKGROUND ACTIVE',
              'Works even when the app is minimized or screen is off.'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary,
              border: Border.all(color: AppColors.borderPrimary, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Page 3: Permission Hub
  Widget _buildPermissionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _allCriticalPermissionsGranted
                  ? AppColors.successGreen.withOpacity(0.15)
                  : AppColors.accentPrimary.withOpacity(0.15),
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  _allCriticalPermissionsGranted
                      ? 'ALL SET!'
                      : 'PERMISSIONS REQUIRED',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _allCriticalPermissionsGranted
                      ? 'All critical permissions granted'
                      : '$_grantedPermissionCount / 4 critical permissions granted',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Permission list
          _buildPermissionRow(
            '📷',
            'Camera',
            'Launch camera with twist',
            _cameraGranted,
            isCritical: true,
          ),
          _buildPermissionRow(
            '🔔',
            'Notifications',
            'System status updates',
            _notificationGranted,
            isCritical: true,
          ),
          _buildPermissionRow(
            '🪟',
            'Display Over Apps',
            'Gesture overlay access',
            _systemAlertGranted,
            isCritical: true,
          ),
          _buildPermissionRow(
            '🔕',
            'DND Control',
            'Do Not Disturb toggle',
            _dndAccessGranted,
            isCritical: true,
          ),
          _buildPermissionRow(
            '🔋',
            'Battery',
            'Background operation',
            _batteryOptimizationGranted,
            isCritical: false,
          ),

          const SizedBox(height: 24),

          // Grant button
          GestureDetector(
            onTap: _isRequestingPermissions ? null : _requestAllPermissions,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _allCriticalPermissionsGranted
                    ? AppColors.successGreen
                    : AppColors.accentPrimary,
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 3.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRequestingPermissions) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _isRequestingPermissions
                        ? 'REQUESTING...'
                        : _allCriticalPermissionsGranted
                            ? 'ALL PERMISSIONS GRANTED'
                            : 'GRANT ALL PERMISSIONS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_allCriticalPermissionsGranted)
            Text(
              'Tap above to grant all permissions at once',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
    String emoji,
    String title,
    String subtitle,
    bool isGranted, {
    bool isCritical = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGranted ? AppColors.successGreen.withOpacity(0.08) : null,
        border: Border.all(
          color: isGranted ? AppColors.successGreen : AppColors.borderPrimary,
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (!isCritical) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textSecondary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'OPTIONAL',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 8,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.successGreen
                  : AppColors.toggleDisarmed,
              border: Border.all(color: AppColors.borderPrimary, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isGranted ? Icons.check : Icons.remove,
              color: isGranted ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Page 4: Ready
  Widget _buildReadyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Success icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.15),
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 3.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '✅',
              style: TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'READY TO GO!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'BARQ X is configured and ready to detect your gestures.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Quick tips
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK START',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 16),
                _buildQuickTip('1.', 'Enable the master toggle'),
                _buildQuickTip('2.', 'Shake your phone for torch'),
                _buildQuickTip('3.', 'Twist for camera'),
                _buildQuickTip('4.', 'Flip face-down for DND'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardShield.withOpacity(0.3),
              border: Border.all(
                color: AppColors.borderPrimary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Runs silently in background 24/7',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuickTip(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            number,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentPrimary,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
