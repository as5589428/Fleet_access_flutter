import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RouteProvider extends ChangeNotifier {
  String _currentRoute = '/';

  String get currentRoute => _currentRoute;

  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      debugPrint('=== Route changed to: $route ===');
      notifyListeners();
    }
  }
}
