import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';

/// 4-step mandatory onboarding briefing
/// Shows features, gestures, permissions, and ready state
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: EdgeInsets.all(AppConfig.screenPadding),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4.0,
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? AppColors.accentPrimary
                            : AppColors.toggleDisarmed,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: EdgeInsets.all(AppConfig.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: () => _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: AppConfig.cardBorderWidth,
                          ),
                        ),
                        child: Text(
                          'BACK',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    )
                  else
                    SizedBox(width: 80.0),
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onComplete();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: AppConfig.cardBorderWidth,
                        ),
                      ),
                      child: Text(
                        _currentPage < 3 ? 'NEXT' : 'START',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
    );
  }

  /// Page 1: Welcome & Features
  Widget _buildPage1() {
    return Padding(
      padding: EdgeInsets.all(AppConfig.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🔦 BARQ X',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                ),
          ),
          SizedBox(height: 16.0),
          Text(
            'Premium Gesture-Utility',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.0),
          Text(
            'Control your Android device with natural gestures. Shake for torch, twist for camera, flip for DND, and more.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.0),
          Container(
            padding: EdgeInsets.all(AppConfig.innerPadding),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textPrimary,
                width: AppConfig.cardBorderWidth,
              ),
            ),
            child: Column(
              children: [
                _featureRow('🔦', 'Torch', 'Kinetic Shake'),
                SizedBox(height: 12.0),
                _featureRow('📷', 'Camera', 'Inertial Twist'),
                SizedBox(height: 12.0),
                _featureRow('🔕', 'DND', 'Surface Flip'),
                SizedBox(height: 12.0),
                _featureRow('⚡', 'Custom', 'Back-Tap'),
                SizedBox(height: 12.0),
                _featureRow('🛡️', 'Protect', 'Pocket Shield'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Page 2: How It Works
  Widget _buildPage2() {
    return Padding(
      padding: EdgeInsets.all(AppConfig.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'HOW IT WORKS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 32.0),
          _instructionBox(
            '1. ARM BARQ X',
            'Enable gestures with the master toggle on the home screen',
          ),
          SizedBox(height: 16.0),
          _instructionBox(
            '2. CHOOSE GESTURES',
            'Enable individual gestures (all on by default)',
          ),
          SizedBox(height: 16.0),
          _instructionBox(
            '3. PERFORM GESTURE',
            'Perform the gesture naturally (shake, twist, flip, etc.)',
          ),
          SizedBox(height: 16.0),
          _instructionBox(
            '4. FEEL FEEDBACK',
            'Get haptic vibration and action executes instantly',
          ),
          SizedBox(height: 16.0),
          _instructionBox(
            '5. CUSTOMIZE',
            'Set custom action for back-tap (default: WhatsApp)',
          ),
        ],
      ),
    );
  }

  /// Page 3: Permissions
  Widget _buildPage3() {
    return Padding(
      padding: EdgeInsets.all(AppConfig.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PERMISSIONS NEEDED',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 32.0),
          Container(
            padding: EdgeInsets.all(AppConfig.innerPadding),
            decoration: BoxDecoration(
              color: AppColors.accentQuaternary.withOpacity(0.2),
              border: Border.all(
                color: AppColors.textPrimary,
                width: AppConfig.cardBorderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _permissionItem('📷 Camera', 'For camera launch gesture'),
                SizedBox(height: 16.0),
                _permissionItem('⏰ Notification', 'For Do Not Disturb mode'),
                SizedBox(height: 16.0),
                _permissionItem('🪟 System Alert', 'For gesture overlay'),
              ],
            ),
          ),
          SizedBox(height: 32.0),
          Text(
            'We will request these after you complete onboarding.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Page 4: Ready
  Widget _buildPage4() {
    return Padding(
      padding: EdgeInsets.all(AppConfig.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '✅',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 64,
                ),
          ),
          SizedBox(height: 16.0),
          Text(
            'YOU\'RE ALL SET!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.0),
          Text(
            'BARQ X is ready to detect your gestures. Start by enabling the master toggle and performing any gesture.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.0),
          Container(
            padding: EdgeInsets.all(AppConfig.innerPadding),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              border: Border.all(
                color: AppColors.successGreen,
                width: AppConfig.secondaryBorderWidth,
              ),
            ),
            child: Text(
              '🎉 Gesture detection is running in the background at all times',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String emoji, String name, String gesture) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(width: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  gesture,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        Icon(Icons.arrow_forward, size: 16),
      ],
    );
  }

  Widget _instructionBox(String title, String description) {
    return Container(
      padding: EdgeInsets.all(AppConfig.innerPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textPrimary,
          width: AppConfig.secondaryBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 4.0),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _permissionItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelSmall),
        SizedBox(width: 12.0),
        Expanded(
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
