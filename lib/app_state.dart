import 'package:flutter/foundation.dart';

// A simple singleton class to hold the application's state.
class AppState extends ChangeNotifier {
  // Private constructor
  AppState._private();

  // Singleton instance
  static final AppState _instance = AppState._private();

  // Factory constructor to return the singleton instance
  factory AppState() => _instance;

  String _userName = '';

  String get userName => _userName;

  set userName(String name) {
    _userName = name;
    // Notify listeners that the state has changed, if you plan to use it with Provider
    notifyListeners();
  }
}
