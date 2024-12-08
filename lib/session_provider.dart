import 'package:flutter/material.dart';

class SessionProvider with ChangeNotifier {
  String _sessionId = '';

  String get sessionId => _sessionId;

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
    notifyListeners(); // Notify listeners when sessionId changes
  }
}
