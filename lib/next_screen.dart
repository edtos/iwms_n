import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'session_provider.dart';  // Import SessionProvider

class NextScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;

  NextScreen({required this.responseData});

  @override
  _NextScreenState createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen> {
  late Map<String, TextEditingController> _controllers;
  String _responseMessage = "";

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  // Initialize text controllers for fields
  void _initializeControllers() {
    final fields = widget.responseData['parsedOutput']['fields'] ?? [];
    _controllers = {
      for (var field in fields)
        field['label']: TextEditingController(text: field['value'] ?? '')
    };
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Method to save data and send the command
  Future<void> _saveData() async {
    // Get the sessionId from SessionProvider
    final sessionId = Provider.of<SessionProvider>(context, listen: false).sessionId;

    if (sessionId.isEmpty) {
      setState(() {
        _responseMessage = "Error: No session ID found.";
      });
      return;
    }

    // Construct the command string from fields
    final fields = widget.responseData['parsedOutput']['fields'] ?? [];
    List<String> commandParts = [];

    for (var field in fields) {
      final label = field['label'] ?? '';
      final value = _controllers[label]?.text ?? '';
      commandParts.add(value.isNotEmpty ? value : '\\t');
    }

    String command = commandParts.join('\t') + '\n';

    // POST request payload
    final url = Uri.parse('http://170.64.223.178:3000/send-command');
    final payload = {
      "sessionId": sessionId,  // Use the sessionId dynamically
      "command": command,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Parse the response and update the UI
        final responseBody = jsonDecode(response.body);
        setState(() {
          _responseMessage = responseBody.toString();
        });
      } else {
        setState(() {
          _responseMessage = "Error: ${response.statusCode}";
        });
      }
    } catch (error) {
      setState(() {
        _responseMessage = "Failed to send data: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.responseData['parsedOutput']['fields'] ?? [];
    final buttons = widget.responseData['parsedOutput']['buttons'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Next Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display editable fields
            Text(
              'Fields:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            ...fields.map<Widget>((field) {
              final label = field['label'] ?? 'Label';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _controllers[label],
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),

            // Save button
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveData,
              child: Text('Save'),
            ),

            // Display dynamic buttons below Save button
            Spacer(),
            if (buttons.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: buttons.map<Widget>((button) {
                  final key = button['key'] ?? 'Key';
                  final action = button['action'] ?? 'Action';

                  return ElevatedButton(
                    onPressed: () {
                      // Placeholder for button actions
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$action triggered!')),
                      );
                    },
                    child: Text('$key: $action'),
                  );
                }).toList(),
              ),

            // Response message at the bottom
            if (_responseMessage.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Response:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _responseMessage,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
