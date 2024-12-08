import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';  // Import LoginScreen for navigation
import 'app_config.dart';

class LogoffHelper {
  // Log off method
  static Future<void> logOff(BuildContext context, String sessionId) async {
    bool isResponseReceived = true;

    // Keep sending the logoff command until no meaningful response is received
    while (isResponseReceived) {
      final logoffResponse = await _sendLogoffCommand(sessionId);

      // Check if the response has "no response"
      if (_isNoResponse(logoffResponse)) {
        // No response received, stop sending logoff commands
        isResponseReceived = false;
        print("No response received, terminating session.");
      } else {
        print("Logoff Response: ${logoffResponse['cleanedOutput']}");
      }
    }

    // After no response, send the end-shell command to terminate the session
    final endShellResponse = await _sendEndShellCommand(sessionId);

    if (_isNoResponse(endShellResponse)) {
      // Handle failure to terminate the session
      _showErrorDialog(context, "Error", "Failed to terminate session.");
    } else {
      // Successfully terminated the session, navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to Login Screen
      );
    }
  }

  // Helper function to check if there was no response
  static bool _isNoResponse(Map<String, dynamic> response) {
    return response['parsedOutput'] != null &&
        response['parsedOutput']['fields'].isEmpty &&
        response['parsedOutput']['menu_options'].isEmpty &&
        response['parsedOutput']['buttons'].isEmpty &&
        response['parsedOutput']['environment'] == null;
  }

  // Send logoff command
  static Future<Map<String, dynamic>> _sendLogoffCommand(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}send-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'command': '\u0018', // Logoff command
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return the parsed response
      } else {
        return {}; // Return an empty map if response is not successful
      }
    } catch (e) {
      print("Error in sending logoff command: $e");
      return {}; // Return an empty map if there is an error
    }
  }

  // Send end-shell command
  static Future<Map<String, dynamic>> _sendEndShellCommand(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}end-shell'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return parsed response on success
      } else {
        return {}; // Return an empty map if the response is not successful
      }
    } catch (e) {
      print("Error in sending end-shell command: $e");
      return {}; // Return an empty map if there is an error
    }
  }

  // Function to show error dialog
  static Future<void> _showErrorDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
        );
      },
    );
  }
}
