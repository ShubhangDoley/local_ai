import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Set this to your development machine's IP and port so a physical phone can reach the backend.
// Example: '192.168.1.42:8000' or '10.0.0.5:8000'
const String backendHost = '172.19.161.41:8000';

enum ChatRole { user, assistant }

class ChatMessage {
  ChatMessage({required this.text, required this.role, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  final String text;
  final ChatRole role;
  final DateTime timestamp;
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      text: 'Tell me what you want to build and I will help.',
      role: ChatRole.assistant,
    ),
  ];

  String _currentInput = '';
  bool _isSending = false;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  String get currentInput => _currentInput;
  bool get isSending => _isSending;
  bool get canSend => _currentInput.trim().isNotEmpty && !_isSending;

  void updateInput(String value) {
    _currentInput = value;
    notifyListeners();
  }

  Future<void> sendUserMessage(String text) async {
    final String sanitizedText = text.trim();
    if (sanitizedText.isEmpty || _isSending) {
      return;
    }

    _messages.add(ChatMessage(text: sanitizedText, role: ChatRole.user));
    _currentInput = '';
    _isSending = true;
    notifyListeners();

    try {
      final String assistantReply = await sendMessageToBackend(sanitizedText);
      _messages.add(
        ChatMessage(text: assistantReply, role: ChatRole.assistant),
      );
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'I could not reach the backend AI. ${e.toString()}',
          role: ChatRole.assistant,
        ),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<String> sendMessageToBackend(String userInput) async {
    // Replace this with your API call.
    final response = await http.post(
      Uri.parse('http://$backendHost/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': userInput}),
    );

    if (response.statusCode != 200) {
      throw Exception('Backend returned status ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data == null || data['response'] == null) {
      throw Exception('Invalid response from backend');
    }

    return data['response'];
  }
}
