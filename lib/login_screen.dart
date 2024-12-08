import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';
import 'session_provider.dart';
import 'app_config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      var uuid = Uuid();
      String sessionId = uuid.v4();

      final sessionPayload = {'sessionId': sessionId};

      final sessionResponse = await http.post(
        Uri.parse('${AppConfig.baseUrl}start-shell'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionPayload),
      );

      if (sessionResponse.statusCode == 200) {
        final commandPayload = {
          'sessionId': sessionId,
          'command': '$username\t$password\n',
        };

        final loginResponse = await http.post(
          Uri.parse('${AppConfig.baseUrl}send-command'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(commandPayload),
        );

        if (loginResponse.statusCode == 200) {
          final responseData = jsonDecode(loginResponse.body);
          Provider.of<SessionProvider>(context, listen: false)
              .setSessionId(sessionId);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(responseData: responseData),
            ),
          );
        } else {
          _showErrorDialog("Login Error", "Invalid username or password.");
        }
      } else {
        _showErrorDialog("Session Creation Error", "Could not create a session.");
      }
    } catch (e) {
      _showErrorDialog("Error", "An error occurred while logging in.");
      print("Login error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _login(context),
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
