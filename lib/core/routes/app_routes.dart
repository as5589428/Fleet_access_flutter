import 'package:fleet_management/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../constants/app_constants.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppConstants.dashboardRoute:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      
      default:
        // For any other route, show MainScreen
        return MaterialPageRoute(builder: (_) => const MainScreen());
    }
  }
}
