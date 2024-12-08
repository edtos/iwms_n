import 'package:flutter/material.dart';
import 'package:iwms/session_provider.dart';
import 'package:provider/provider.dart';
import 'logoff_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'next_screen.dart';

class MenuScreen extends StatelessWidget {
  final Map<String, dynamic> responseData;

  // Constructor to accept the response data
  MenuScreen({required this.responseData});

  @override
  Widget build(BuildContext context) {
    // Debugging the structure of the responseData
    print('Response Data: $responseData');

    // Extracting menu options and buttons from responseData
    List<Map<String, dynamic>> menuOptions = List<Map<String, dynamic>>.from(responseData['parsedOutput']['menu_options'] ?? []);
    List<Map<String, dynamic>> buttons = List<Map<String, dynamic>>.from(responseData['parsedOutput']['buttons'] ?? []);

    // Debug prints to ensure menu options and buttons are being parsed correctly
    print('Menu Options: $menuOptions');
    print('Buttons: $buttons');

    // Get sessionId from SessionProvider
    final sessionId = Provider.of<SessionProvider>(context).sessionId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              LogoffHelper.logOff(context, sessionId); // Log off action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (menuOptions.isNotEmpty) ...[
              // Display Menu Options if available
              Text('Menu Options:', style: Theme.of(context).textTheme.titleLarge),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: menuOptions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(menuOptions[index]['label'] ?? 'Untitled Option'),
                    subtitle: menuOptions[index]['id'] != null ? Text('ID: ${menuOptions[index]['id']}') : null,
                    onTap: () {
                      // Handle menu item selection
                      String selectedOption = menuOptions[index]['id'].toString();
                      print('Selected Option: ${menuOptions[index]['label']}');
                      _sendCommandAndNavigate(context, sessionId, selectedOption);
                    },
                  );
                },
              ),
            ],
            if (buttons.isNotEmpty) ...[
              // Display Action Buttons if available
              SizedBox(height: 16),
              Text('Actions:', style: Theme.of(context).textTheme.titleLarge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buttons.map((button) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle button press (e.g., logging actions or triggering specific functionality)
                        print('Action: ${button['action']}');
                      },
                      child: Text('${button['key']} - ${button['action']}'),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Define the _sendCommandAndNavigate method
  void _sendCommandAndNavigate(BuildContext context, String sessionId, String selectedOption) async {
    // Add \n to the selectedOption as per the requirement
    String command = '$selectedOption\n'; // Ensure the \n is appended

    var payload = {
      "sessionId": sessionId,
      "command": command, // Send the command with \n appended
    };

    // Print the request sent
    print('Sending request: $payload');

    // Send POST request to the server and await response
    final response = await _sendPostRequest(payload);

    // Print the response received
    if (response != null) {
      print('Received response: $response');

      // Parse the response and navigate to the next screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NextScreen(responseData: response),
        ),
      );
    } else {
      // Show error message if failed
      print('Failed to load the response');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load the response')),
      );
    }
  }

  // Function to send POST request
  Future<Map<String, dynamic>?> _sendPostRequest(Map<String, dynamic> payload) async {
    String url = 'http://170.64.223.178:3000/send-command'; // API endpoint
    print('POST Request URL: $url');

    try {
      // Send POST request to the server
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: Failed to send command. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Catch and log any error that occurs during the HTTP request
      print('Error occurred: $e');
      return null;
    }
  }
}
