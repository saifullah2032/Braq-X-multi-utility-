// DEBUG: Add this to lib/screens/home_screen.dart initState for debugging
// Add these imports at the top:
// import 'dart:developer' as developer;

// In _HomeScreenState.initState(), add logging:
void initState() {
  super.initState();
  developer.log('HomeScreen initialized', name: 'HomeScreen');
  
  // Initialize gesture integration on mount
  WidgetsBinding.instance.addPostFrameCallback((_) {
    developer.log('Initializing gesture integration service...', name: 'HomeScreen');
    try {
      ref.read(gestureIntegrationProvider).initialize().then((_) {
        developer.log('Gesture integration service initialized successfully', name: 'HomeScreen');
      }).catchError((e, st) {
        developer.log('Error initializing gesture service: $e', name: 'HomeScreen', error: e, stackTrace: st);
      });
    } catch (e, st) {
      developer.log('Error in gesture initialization: $e', name: 'HomeScreen', error: e, stackTrace: st);
    }
  });
}
