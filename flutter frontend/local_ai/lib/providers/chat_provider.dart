import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'model_provider.dart';

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
  
  ModelProvider? _modelProvider;
  dynamic _localChatSession;
  LocalModel? _lastLocalModel;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  String get currentInput => _currentInput;
  bool get isSending => _isSending;
  bool get canSend => _currentInput.trim().isNotEmpty && !_isSending;

  void updateModelProvider(ModelProvider modelProvider) {
    _modelProvider = modelProvider;
  }

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

    // Check if Local AI is active and configured
    if (_modelProvider != null && _modelProvider!.isLocalMode) {
      final activeModel = _modelProvider!.activeModel;
      if (activeModel == null) {
        _messages.add(
          ChatMessage(
            text: 'No local model downloaded/selected. Please download and select a model first.',
            role: ChatRole.assistant,
          ),
        );
        _isSending = false;
        notifyListeners();
        return;
      }

      try {
        // Reset session if the selected model changed
        if (_lastLocalModel?.id != activeModel.id) {
          if (_localChatSession != null) {
            try {
              await _localChatSession.close();
            } catch (_) {}
            _localChatSession = null;
          }
          _lastLocalModel = activeModel;
        }

        // Initialize active model session
        if (_localChatSession == null) {
          final inferenceModel = await FlutterGemma.getActiveModel(
            maxTokens: 2048,
          );
          _localChatSession = await inferenceModel.createChat(
            temperature: 0.7,
          );
        }

        // Add the user message
        final userMsg = Message.text(text: sanitizedText, isUser: true);
        await _localChatSession.addQueryChunk(userMsg);

        // Get the streaming response from local model
        final responseStream = _localChatSession.generateChatResponseAsync();

        // Create a placeholder message in chat list
        final ChatMessage assistantMessagePlaceholder = ChatMessage(
          text: '',
          role: ChatRole.assistant,
        );
        _messages.add(assistantMessagePlaceholder);
        final int assistantMsgIndex = _messages.length - 1;

        final StringBuffer buffer = StringBuffer();

        await for (final response in responseStream) {
          String chunk = '';
          try {
            final dynamic r = response;
            if (r is String) {
              chunk = r;
            } else {
              try {
                chunk = r.text;
              } catch (_) {
                try {
                  chunk = r.token;
                } catch (_) {
                  chunk = r.toString();
                }
              }
            }
          } catch (_) {}

          if (chunk.isNotEmpty) {
            buffer.write(chunk);
            _messages[assistantMsgIndex] = ChatMessage(
              text: buffer.toString(),
              role: ChatRole.assistant,
              timestamp: assistantMessagePlaceholder.timestamp,
            );
            notifyListeners();
          }
        }
      } catch (e) {
        _messages.add(
          ChatMessage(
            text: 'On-device AI failed: ${e.toString()}',
            role: ChatRole.assistant,
          ),
        );
      } finally {
        _isSending = false;
        notifyListeners();
      }
      return;
    }

    // Backend AI Flow
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

  @override
  void dispose() {
    if (_localChatSession != null) {
      try {
        _localChatSession.close();
      } catch (_) {}
    }
    super.dispose();
  }
}
