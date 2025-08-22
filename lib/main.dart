import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  await ThemeService().initializeTheme();

  // Set edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'AI Chat Assistant',
          debugShowCheckedModeBanner: false,

          // Modern themes with 2025 design trends
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,

          // Enhanced theme animation - faster and smoother
          themeAnimationDuration: const Duration(milliseconds: 150),
          themeAnimationCurve: Curves.easeOutCubic,

          home: const LoginPage(),

          // Custom scroll behavior for all platforms
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            scrollbars: false,
          ),
        );
      },
    );
  }
}
